import 'dart:async';

abstract class NfcService {
  Stream<String> get detectedUids;

  /// Starts a foreground scan when the platform requires a user gesture.
  ///
  /// Services with an always-on reader return `null`. A successful foreground
  /// scan returns the normalized UID and also emits it on [detectedUids].
  Future<String?> startScan();

  Future<void> scanDemo(String uid);

  void dispose();
}

class DemoNfcService implements NfcService {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get detectedUids => _controller.stream;

  @override
  Future<String?> startScan() async => null;

  @override
  Future<void> scanDemo(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!_controller.isClosed) {
      _controller.add(uid);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class NfcScanException implements Exception {
  const NfcScanException(this.message, {this.wasCancelled = false});

  final String message;
  final bool wasCancelled;

  @override
  String toString() => message;
}
