import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/trip_catalog_store.dart';

JapanMemoryLocation? galleryMemoryLocationFor(
  String tripSlug,
  int memoryIndex,
) {
  final locations = galleryMemoryLocationsFor(tripSlug);
  if (locations.isEmpty) {
    return null;
  }
  return locations[memoryIndex % locations.length];
}

List<JapanMemoryLocation> galleryMemoryLocationsFor(String tripSlug) {
  return TripCatalogStore.instance.memoryLocationsFor(tripSlug);
}

List<JapanMemoryAsset> defaultGalleryMediaFor(
  TripGalleryItem trip,
  int memoryIndex, {
  required bool portrait,
}) {
  final location = galleryMemoryLocationFor(trip.slug, memoryIndex);
  return location?.media ??
      <JapanMemoryAsset>[
        JapanMemoryAsset(
          assetPath: portrait ? trip.portraitAssetPath : trip.assetPath,
          kind: JapanMemoryKind.photo,
        ),
      ];
}

List<String> galleryPhotoChoicesFor(TripGalleryItem trip) {
  final choices = <String>{
    for (final location in galleryMemoryLocationsFor(trip.slug))
      for (final media in location.media)
        if (!media.isVideo) media.assetPath,
  };
  if (choices.isEmpty) {
    choices
      ..add(trip.assetPath)
      ..add(trip.portraitAssetPath);
  }
  return choices.toList(growable: false);
}

// Add bundled trinket files under assets/images/experience/, register their
// paths here, then rebuild EverAfter. Browser uploads are intentionally absent.
const List<String> galleryTrinketAssetChoices = <String>[
  'assets/images/experience/china-nfc-magnet-reveal.png',
  'assets/images/experience/hong-kong-nfc-magnet-reveal.png',
  'assets/images/experience/japan-nfc-magnet-reveal-fox.png',
  'assets/images/experience/taiwan-nfc-magnet-reveal-bubble-tea.png',
  'assets/images/experience/vietnam-nfc-magnet-reveal-lotus.png',
];
