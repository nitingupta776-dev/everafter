# Security model

EverAfter is a local-only application. It has no remote database, account
system, object storage, edge functions, access tokens, or background sync.

## Gallery access

`/admin/gallery` opens directly. There is no app-level administrator login;
physical access to the device or access to the browser/operating-system profile
is the security boundary. Use the platform's screen lock and separate user
accounts when gallery editing must be restricted.

## Local persistence

The global gallery layout is loaded automatically from the bundled
`assets/data/gallery_layouts.json`. Browser admin can write a JSON file only
after the user explicitly chooses the destination through the browser's save
picker. The browser does not create a hidden second layout in site storage.

Native device differences are serialized into Flutter preferences under
`everafter.gallery-layout.device-overrides.v1`. They are patches over the
global baseline rather than a second global source of truth. An older
`everafter.gallery-layout.v1` snapshot is migrated locally on first load.
The gallery editor does not accept browser file uploads. New trip media and
trinkets must be added to the source asset folders and registered before the app
is rebuilt. Previously saved embedded trinkets remain readable for backwards
compatibility.

This data is not an encrypted vault. Anyone who can read the application data
or browser profile may inspect titles, dates, layout metadata, and embedded
images. Clearing native application data or uninstalling EverAfter deletes that
device's override, but the bundled global JSON remains part of the app.
Keep original media separately and do not copy a private preferences file into
the public repository.

Legacy HTTP-backed trinkets are discarded when an older snapshot is loaded.
EverAfter never fetches gallery layouts or trinket images from the network.

## Native signing

The public Xcode project has no Apple Development Team ID. Configure your own
team locally in Xcode when building for a physical device; do not commit that
identifier back to the public repository.
