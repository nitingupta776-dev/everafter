import 'dart:async';

import 'package:everafter/data/trip_repository.dart';
import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/services/nfc_service.dart';
import 'package:everafter/services/nfc_service_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final museumControllerProvider =
    NotifierProvider<MuseumController, MuseumState>(MuseumController.new);

@immutable
class MuseumState {
  const MuseumState({
    required this.artifacts,
    this.selectedArtifact,
    this.isScanning = false,
    this.lastDetectedUid,
    this.nfcDetectionRevision = 0,
  });

  final List<TravelArtifact> artifacts;
  final TravelArtifact? selectedArtifact;
  final bool isScanning;
  final String? lastDetectedUid;
  final int nfcDetectionRevision;

  int get countryCount =>
      artifacts.map((artifact) => artifact.country).toSet().length;

  MuseumState copyWith({
    List<TravelArtifact>? artifacts,
    TravelArtifact? selectedArtifact,
    bool clearSelectedArtifact = false,
    bool? isScanning,
    String? lastDetectedUid,
    int? nfcDetectionRevision,
  }) {
    return MuseumState(
      artifacts: artifacts ?? this.artifacts,
      selectedArtifact: clearSelectedArtifact
          ? null
          : selectedArtifact ?? this.selectedArtifact,
      isScanning: isScanning ?? this.isScanning,
      lastDetectedUid: lastDetectedUid ?? this.lastDetectedUid,
      nfcDetectionRevision: nfcDetectionRevision ?? this.nfcDetectionRevision,
    );
  }
}

class MuseumController extends Notifier<MuseumState> {
  StreamSubscription<String>? _nfcSubscription;

  @override
  MuseumState build() {
    final repository = ref.watch(tripRepositoryProvider);
    final nfcService = ref.watch(nfcServiceProvider);

    _nfcSubscription?.cancel();
    _nfcSubscription = nfcService.detectedUids.listen((uid) {
      final artifact = repository.findByUid(uid);
      if (artifact == null) {
        state = state.copyWith(isScanning: false, lastDetectedUid: uid);
        return;
      }
      state = state.copyWith(
        selectedArtifact: artifact,
        isScanning: false,
        lastDetectedUid: uid,
        nfcDetectionRevision: state.nfcDetectionRevision + 1,
      );
    });
    ref.onDispose(() => _nfcSubscription?.cancel());

    return MuseumState(artifacts: repository.artifacts);
  }

  Future<void> requestDemoScan() async {
    if (state.isScanning) {
      return;
    }
    final repository = ref.read(tripRepositoryProvider);
    state = state.copyWith(isScanning: true);
    await ref.read(nfcServiceProvider).scanDemo(repository.demoArtifact.uid);
  }

  Future<String?> requestNfcScan() async {
    if (state.isScanning) {
      return null;
    }

    state = state.copyWith(isScanning: true);
    try {
      final uid = await ref.read(nfcServiceProvider).startScan();
      if (uid == null) {
        state = state.copyWith(isScanning: false);
        return null;
      }

      final artifact = ref.read(tripRepositoryProvider).findByUid(uid);
      if (artifact == null) {
        state = state.copyWith(isScanning: false, lastDetectedUid: uid);
        return 'This magnet is not linked to a trip yet. UID: $uid';
      }
      return null;
    } on NfcScanException catch (error) {
      state = state.copyWith(isScanning: false);
      return error.wasCancelled ? null : error.message;
    } catch (_) {
      state = state.copyWith(isScanning: false);
      return 'EverAfter could not scan this magnet. Please try again.';
    }
  }

  void selectArtifact(String uid) {
    final artifact = ref.read(tripRepositoryProvider).artifactByUid(uid);
    state = state.copyWith(
      selectedArtifact: artifact,
      isScanning: false,
      lastDetectedUid: uid,
      nfcDetectionRevision: state.nfcDetectionRevision + 1,
    );
  }

  void returnToIdle() {
    if (state.selectedArtifact == null && !state.isScanning) {
      return;
    }
    state = state.copyWith(clearSelectedArtifact: true, isScanning: false);
  }
}
