# Security model

EverAfter runs as a public-safe demo by default. Backend configuration is
optional and is never committed.

## Gallery authorization

- Anonymous callers can select only from `gallery_layouts_public_safe`. The
  legacy public view is revoked. The safe view removes travel dates and the
  private media-related fields described below from the layout JSON.
- The base `gallery_layouts` table is available only to authenticated users
  listed in `gallery_admins`.
- The `/admin/gallery` route requires the same owner sign-in. Its access token
  is held in memory and is not persisted to browser or desktop storage.
- Database RLS remains authoritative. The route guard is usability and
  defense-in-depth, not the security boundary.

The public migrations intentionally leave `gallery_admins` empty. Provision an
owner explicitly after creating and verifying the account:

```sh
npx @insforge/cli db query \
  "INSERT INTO public.gallery_admins (user_id) VALUES ('<auth-user-uuid>') ON CONFLICT DO NOTHING;"
```

Remove access with a targeted delete from that table. Never hardcode an owner
UUID or email address in a public migration.

## Upload boundary

`upload-gallery-trinket` verifies the caller's JWT and `gallery_admins`
membership before using its server-only admin client. It also:

- restricts browser origins to the documented local admin origins;
- caps the streamed request body and decoded image at 2 MB;
- accepts only PNG, JPEG, and WebP with matching file signatures;
- generates object keys server-side;
- limits each administrator to ten upload attempts per minute; and
- returns generic storage errors without leaking backend details.

New uploads use server-generated `published-trinkets/` keys. The anonymous
gallery view omits legacy storage-backed trinkets, custom frame titles, selected
photo paths and crop metadata, private local trinket paths, storage keys, and
custom trinket labels. Public frames fall back to the bundled demo media, so
older private filenames are not exposed merely because they remain in an
administrator's saved layout.

The `gallery-trinkets` bucket is public-read because museum displays need direct
image URLs. Treat every uploaded object as public. Personal media belongs only
in the ignored private overlay and must never enter this bucket.

## Native signing

The public Xcode project has no Apple Development Team ID. Configure your own
team locally in Xcode when building for a physical device; do not commit that
identifier back to the public repository.
