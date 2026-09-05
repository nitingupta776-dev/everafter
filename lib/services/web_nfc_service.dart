import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:everafter/services/nfc_service.dart';

bool get webNfcAvailable => globalContext.has('NDEFReader');

@JS('NDEFReader')
extension type _NDEFReader._(JSObject _) implements JSObject {
  external _NDEFReader();
  external JSPromise<JSAny?> scan();
  external set onreading(JSFunction? handler);
  external set onreadingerror(JSFunction? handler);
}

extension type _NDEFReadingEvent(JSObject _) implements JSObject {
  external String get serialNumber;
}

class WebNfcService implements NfcService {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get detectedUids => _controller.stream;

  @override
  Future<String?> startScan() async {
    if (!webNfcAvailable) {
      throw const NfcScanException(
        'Web NFC requires Chrome on Android. It is not supported in this browser.',
      );
    }

    final reader = _NDEFReader();
    final completer = Completer<String?>();

    reader.onreading = ((JSObject event) {
      final uid = _NDEFReadingEvent(event).serialNumber.toUpperCase();
      if (!_controller.isClosed) _controller.add(uid);
      if (!completer.isCompleted) completer.complete(uid);
    }).toJS;

    reader.onreadingerror = ((JSObject _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const NfcScanException('Could not read the NFC tag. Please try again.'),
        );
      }
    }).toJS;

    try {
      await reader.scan().toDart;
    } catch (_) {
      throw const NfcScanException(
        'NFC permission was denied or could not start.',
      );
    }

    return completer.future;
  }

  @override
  Future<void> scanDemo(String uid) async {
    if (!_controller.isClosed) _controller.add(uid);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
