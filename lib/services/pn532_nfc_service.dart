import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:everafter/services/nfc_service.dart';
import 'package:flutter/foundation.dart';

class Pn532NfcService implements NfcService {
  Pn532NfcService({
    this.executable = 'nfc-poll',
    this.arguments = const <String>[],
    this.retryDelay = const Duration(seconds: 2),
  }) {
    _controller = StreamController<String>.broadcast(onListen: _startPolling);
  }

  final String executable;
  final List<String> arguments;
  final Duration retryDelay;

  late final StreamController<String> _controller;
  Process? _process;
  bool _isPolling = false;
  bool _isDisposed = false;
  bool _reportedLaunchFailure = false;
  String? _lastUid;
  DateTime? _lastDetection;

  @override
  Stream<String> get detectedUids => _controller.stream;

  @override
  Future<String?> startScan() async => null;

  void _startPolling() {
    if (_isPolling || _isDisposed) {
      return;
    }
    _isPolling = true;
    unawaited(_pollContinuously());
  }

  Future<void> _pollContinuously() async {
    while (!_isDisposed && _controller.hasListener) {
      try {
        final process = await Process.start(executable, arguments);
        _process = process;
        _reportedLaunchFailure = false;

        final stderrDone = process.stderr.drain<void>();
        await for (final line
            in process.stdout
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          final uid = parsePn532Uid(line);
          if (uid != null) {
            _emitUid(uid);
          }
        }
        await process.exitCode;
        await stderrDone;
      } on ProcessException catch (error) {
        if (!_reportedLaunchFailure) {
          debugPrint(
            'EverAfter could not start $executable: ${error.message}. '
            'Install/configure libnfc or use EVERAFTER_NFC_MODE=demo.',
          );
          _reportedLaunchFailure = true;
        }
      } finally {
        _process = null;
      }

      if (!_isDisposed && _controller.hasListener) {
        await Future<void>.delayed(retryDelay);
      }
    }
    _isPolling = false;
  }

  void _emitUid(String uid) {
    if (_isDisposed || _controller.isClosed) {
      return;
    }
    final now = DateTime.now();
    final isRecentDuplicate =
        uid == _lastUid &&
        _lastDetection != null &&
        now.difference(_lastDetection!) < const Duration(seconds: 4);
    if (isRecentDuplicate) {
      return;
    }
    _lastUid = uid;
    _lastDetection = now;
    _controller.add(uid);
  }

  @override
  Future<void> scanDemo(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _emitUid(uid);
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _process?.kill(ProcessSignal.sigterm);
    unawaited(_controller.close());
  }
}

String? parsePn532Uid(String line) {
  final separator = line.indexOf(':');
  if (separator < 0 ||
      !line.substring(0, separator).toUpperCase().contains('UID')) {
    return null;
  }

  final bytes = RegExp(r'\b[0-9a-fA-F]{2}\b')
      .allMatches(line.substring(separator + 1))
      .map((match) => match.group(0)!.toUpperCase())
      .toList(growable: false);
  if (bytes.length < 4 || bytes.length > 10) {
    return null;
  }
  return bytes.join(':');
}
