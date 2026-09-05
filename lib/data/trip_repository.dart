import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/models/travel_artifact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return const TripRepository();
});

class TripRepository {
  const TripRepository();

  List<TravelArtifact> get artifacts => TripCatalogStore.instance.artifacts;

  TravelArtifact? findByUid(String uid) {
    for (final artifact in artifacts) {
      if (artifact.uid == uid) {
        return artifact;
      }
    }
    return null;
  }

  TravelArtifact artifactByUid(String uid) {
    return findByUid(uid) ?? artifacts.first;
  }

  TravelArtifact get demoArtifact => artifacts.first;
}
