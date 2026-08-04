import {
  createAdminClient,
  createClient,
} from 'npm:@insforge/sdk@1.5.2';

const maxImageBytes = 2 * 1024 * 1024;
const maxBase64Length = Math.ceil(maxImageBytes / 3) * 4 + 8;
const maxRequestBytes = maxBase64Length + 2048;
const uploadsPerMinute = 10;
const allowedOrigins = new Set([
  'http://127.0.0.1:8080',
  'http://localhost:8080',
]);

const supportedImages = new Map<string, { extension: string; matches: (bytes: Uint8Array) => boolean }>([
  [
    'image/png',
    {
      extension: 'png',
      matches: (bytes) =>
        bytes.length >= 8 &&
        bytes[0] === 0x89 &&
        bytes[1] === 0x50 &&
        bytes[2] === 0x4e &&
        bytes[3] === 0x47 &&
        bytes[4] === 0x0d &&
        bytes[5] === 0x0a &&
        bytes[6] === 0x1a &&
        bytes[7] === 0x0a,
    },
  ],
  [
    'image/jpeg',
    {
      extension: 'jpg',
      matches: (bytes) =>
        bytes.length >= 3 &&
        bytes[0] === 0xff &&
        bytes[1] === 0xd8 &&
        bytes[2] === 0xff,
    },
  ],
  [
    'image/webp',
    {
      extension: 'webp',
      matches: (bytes) =>
        bytes.length >= 12 &&
        ascii(bytes, 0, 4) === 'RIFF' &&
        ascii(bytes, 8, 12) === 'WEBP',
    },
  ],
]);

function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get('Origin');
  if (origin === null || !allowedOrigins.has(origin)) {
    return { Vary: 'Origin' };
  }
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    Vary: 'Origin',
  };
}

function json(request: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(request), 'Content-Type': 'application/json' },
  });
}

function safeSegment(value: unknown): string | null {
  if (typeof value !== 'string' || !/^[a-z0-9][a-z0-9-]{0,63}$/.test(value)) {
    return null;
  }
  return value;
}

function ascii(bytes: Uint8Array, start: number, end: number): string {
  return String.fromCharCode(...bytes.slice(start, end));
}

function decodeBase64(value: string): Uint8Array | null {
  if (value.length === 0 || value.length > maxBase64Length) return null;
  try {
    const binary = atob(value);
    if (binary.length > maxImageBytes) return null;
    return Uint8Array.from(binary, (character) => character.charCodeAt(0));
  } catch {
    return null;
  }
}

async function readJsonBody(
  request: Request,
): Promise<Record<string, unknown> | 'too-large' | null> {
  const reader = request.body?.getReader();
  if (!reader) return null;
  const chunks: Uint8Array[] = [];
  let received = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    received += value.byteLength;
    if (received > maxRequestBytes) {
      await reader.cancel();
      return 'too-large';
    }
    chunks.push(value);
  }
  const body = new Uint8Array(received);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    const parsed = JSON.parse(new TextDecoder().decode(body));
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? parsed as Record<string, unknown>
      : null;
  } catch {
    return null;
  }
}

export default async function (request: Request): Promise<Response> {
  const origin = request.headers.get('Origin');
  if (origin !== null && !allowedOrigins.has(origin)) {
    return json(request, { error: 'Origin not allowed' }, 403);
  }
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }
  if (request.method !== 'POST') {
    return json(request, { error: 'Method not allowed' }, 405);
  }

  const contentLength = Number(request.headers.get('Content-Length') ?? '0');
  if (Number.isFinite(contentLength) && contentLength > maxRequestBytes) {
    return json(request, { error: 'Request is too large' }, 413);
  }

  const baseUrl = Deno.env.get('INSFORGE_BASE_URL');
  if (!baseUrl) {
    return json(request, { error: 'Authentication is not configured' }, 500);
  }

  const authorization = request.headers.get('Authorization');
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) {
    return json(request, { error: 'Authentication required' }, 401);
  }

  const userClient = createClient({ baseUrl, accessToken: token });
  const { data: currentUser, error: userError } =
    await userClient.auth.getCurrentUser();
  const userId = currentUser?.user?.id;
  if (userError || !userId) {
    return json(request, { error: 'Authentication required' }, 401);
  }

  const { data: memberships, error: membershipError } = await userClient.database
    .from('gallery_admins')
    .select('user_id')
    .eq('user_id', userId)
    .limit(1);
  if (membershipError || !memberships?.length) {
    return json(request, { error: 'Administrator access required' }, 403);
  }

  const apiKey = Deno.env.get('EVERAFTER_ADMIN_API_KEY');
  if (!apiKey) {
    return json(request, { error: 'Storage is not configured' }, 500);
  }
  const admin = createAdminClient({ baseUrl, apiKey });
  const { data: rateAllowed, error: rateError } = await admin.database.rpc(
    'claim_gallery_upload_slot',
    { p_user_id: userId, p_limit: uploadsPerMinute },
  );
  if (rateError) {
    return json(request, { error: 'Could not verify upload rate' }, 500);
  }
  if (rateAllowed !== true) {
    return json(request, { error: 'Upload rate limit exceeded' }, 429);
  }

  const body = await readJsonBody(request);
  if (body === 'too-large') {
    return json(request, { error: 'Request is too large' }, 413);
  }
  if (body === null) {
    return json(request, { error: 'Invalid JSON body' }, 400);
  }

  const tripSlug = safeSegment(body.tripSlug);
  const trinketId = safeSegment(body.trinketId);
  const mimeType = typeof body.mimeType === 'string' ? body.mimeType : '';
  const imageType = supportedImages.get(mimeType);
  const base64 = typeof body.base64 === 'string' ? body.base64 : '';
  if (!tripSlug || !trinketId || !imageType) {
    return json(request, { error: 'Invalid trinket upload' }, 400);
  }

  const binary = decodeBase64(base64);
  if (!binary) {
    return json(request, { error: 'Trinket images must be valid and 2 MB or smaller' }, 413);
  }
  if (!imageType.matches(binary)) {
    return json(request, { error: 'Image content does not match its MIME type' }, 415);
  }

  const key =
    `published-trinkets/${tripSlug}/${trinketId}-${crypto.randomUUID()}.${imageType.extension}`;
  const file = new File([binary], `${trinketId}.${imageType.extension}`, {
    type: mimeType,
  });
  const { data, error } = await admin.storage
    .from('gallery-trinkets')
    .upload(key, file);
  if (error || !data) {
    return json(request, { error: 'Upload failed' }, 500);
  }
  return json(request, { key: data.key, url: data.url });
}
