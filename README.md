# EverAfter

EverAfter is a Flutter prototype for a local-first interactive museum of travel souvenirs. An idle museum display waits for an NFC-tagged artifact, opens an artifact intro, then moves into a calm exhibit flow with archival labels, paper texture, and collection browsing.

This public repository contains anonymous demo records and redistributable placeholder media only. Personal photos, videos, travel dates, NFC identifiers, backend credentials, and local design captures are intentionally excluded.

## What is implemented

- Flutter app scaffolded for Android, iOS, Linux, macOS, and web.
- Riverpod app state with a replaceable NFC service boundary.
- GoRouter routes for idle, artifact intro, exhibit, and collection catalogue.
- Anonymous seeded artifact data, clearly marked demo NFC UIDs, and a bundled fridge-magnet GLB.
- Custom-painted paper texture, ambient dust and light, rotating exhibit-object stage, Hero transitions, catalogue cards, and museum labels.
- Nine-second cinematic splash using the public-domain Erratic Cursive font and Texturelabs Paper 320.
- Public-safe gallery placeholders derived from NASA Blue Marble imagery and a generated abstract demo video.
- Widget tests for the idle museum and demo NFC-to-exhibit flow.

## Run

```sh
flutter pub get
flutter run -d chrome
```

The demo works without a backend. To connect your own InsForge project, copy
`.env.example` to `.env.local`, fill in your own public project URL and anon
key, and run with `--dart-define-from-file=.env.local`. Never commit that file.

## Verify

```sh
dart format .
flutter analyze
flutter test
```

## Gallery admin

Open `/admin/gallery` in the web app to sign in and arrange the cinematic
gallery walls. The route, database writes, and upload function all require an
authenticated user whose ID has been explicitly added to `gallery_admins`.
Choose a trip, then drag a frame or trinket on the canvas or enter exact
position, size, scale, rotation, and frame-style values in the inspector.
Items can be hidden and restored from the item picker. **Save changes** stores
the layout in the shared EverAfter database; **Reset** restores the original
layout for the selected trip. Each device keeps the last successful layout as
an offline fallback. Existing browser-only layouts migrate automatically the
first time that browser opens this database-backed build.
Running gallery displays refresh the shared layout every five seconds, while an
admin with unsaved edits is left untouched until those changes are saved.

No administrator is created by the public migrations. After creating and
verifying an owner account in your own InsForge project, grant it access from
an authenticated CLI session:

```sh
npx @insforge/cli db query \
  "INSERT INTO public.gallery_admins (user_id) VALUES ('<auth-user-uuid>') ON CONFLICT DO NOTHING;"
```

Admin access tokens are kept in memory only; closing or restarting the app
requires signing in again. Anonymous displays read a sanitized database view
that omits travel dates and cannot mutate the source layouts.

Custom trinket images are uploaded to the public `gallery-trinkets`
object-storage bucket under server-generated `published-trinkets/` keys. The
anonymous view omits legacy storage objects, custom frame media paths and
titles, crop metadata, storage keys, and custom trinket labels. Public frames
fall back to the bundled demo media. The database stores each new image's URL
and storage key rather than embedding the full image in the layout row. That
bucket is intentionally public-read so
gallery displays can render its objects. Upload only artwork that is safe to be
world-readable; never upload personal photographs to it.

## Privacy and public sharing

The Git boundary deliberately excludes:

- `assets/memories/`, imported trip photography, reels, manifests, and keepsake scans;
- exact travel dates and physical NFC tag identifiers;
- `.env*` credentials (except the blank `.env.example`) and local InsForge state;
- model reference photos, design-QA captures, temporary files, logs, and generated CAD/mesh exports;
- audio and fonts whose licenses do not permit source redistribution.

See [`docs/PRIVATE_MEDIA.md`](docs/PRIVATE_MEDIA.md) before adding your own
collection. Run `git add -n .` before every public commit to confirm none of the
ignored local archive is entering Git.

The database and upload authorization model is documented in
[`docs/SECURITY.md`](docs/SECURITY.md).

## NFC integration point

The app uses `DemoNfcService` by default. On Linux, setting
`EVERAFTER_NFC_MODE=pn532` activates `Pn532NfcService`, which repeatedly runs
`nfc-poll`, parses NFCID1 UIDs, suppresses immediate duplicate reads, and emits
them on the same `detectedUids` stream.

## Raspberry Pi OS — native application

Use a Raspberry Pi 4 or 5 with 64-bit Raspberry Pi OS Desktop and the current
Flutter Linux ARM64 stable SDK. The project now includes a GTK Linux runner; it
does not require Chromium or a local web server.

First configure the PN532 for `libnfc` using I2C, SPI, or UART and verify that
this command prints the tag UID:

```sh
nfc-poll
```

Then build and start the native fullscreen application:

```sh
./tool/build_pi.sh
./tool/run_pi.sh
```

The launcher defaults to `EVERAFTER_FULLSCREEN=1` and
`EVERAFTER_NFC_MODE=pn532`. For UI-only testing, run:

```sh
EVERAFTER_NFC_MODE=demo EVERAFTER_FULLSCREEN=0 ./tool/run_pi.sh
```

## Redistributable assets

- Paper 320: Texturelabs, free for commercial use.
- Erratic Cursive: GGBotNet, released under CC0/public domain.
- Earth imagery: NASA Visible Earth, public domain.
- Interaction sounds: generated specifically for EverAfter without third-party samples.

The downloaded font license texts are retained in `assets/licenses/`.
