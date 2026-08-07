# Private media boundary

The public EverAfter repository is a runnable demo, not a copy of a personal
travel archive. The app uses anonymous NFC identifiers, omitted dates, NASA
globe artwork, and an abstract generated video anywhere a photo or reel would
normally appear.

Keep personal material in the existing ignored locations:

- `assets/memories/` for photos, videos, posters, manifests, and keepsake scans;
- `assets/images/japan/`, `assets/images/trips/`, and JPG files under
  `assets/images/taste/` for imported or derived trip photography;
- `models/fridge_magnet/reference_images/` for object reference photography;
- `artifacts/` and `tmp/` for screenshots, comparisons, and working files.

Those paths are deliberately absent from `pubspec.yaml`, so a clean clone does
not require or bundle them. If you build a private edition, keep its asset
manifest and data bindings in an ignored local overlay or a separate private
repository. Do not replace the public demo paths with personal filenames in a
public branch.

The gallery editor does not accept browser uploads. Add private trip media under
`assets/memories/<trip-slug>/`, then register it in the trip's private data and
asset manifest before rebuilding. Bundled trinket artwork lives under
`assets/images/experience/` and is listed in `galleryTrinketAssetChoices` in
`lib/data/gallery_memory_content.dart`. Keep private originals in the ignored
overlay described above and never commit exported preference data.

The shared layout source is `assets/data/gallery_layouts.json`. It must contain
only public-safe asset paths and labels on a public branch. Device-specific
layout overrides remain in platform application preferences and should not be
copied into the repository.

Before publishing a change, review the exact candidate set:

```sh
git add -n .
git status --short --ignored
```

Also search candidate source and documentation for credentials, absolute home
paths, physical NFC UIDs, social-media permalinks, and exact private dates.
