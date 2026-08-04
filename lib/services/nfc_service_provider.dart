import 'package:everafter/services/nfc_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nfc_service_factory_stub.dart'
    if (dart.library.io) 'nfc_service_factory_io.dart';

final nfcServiceProvider = Provider<NfcService>((ref) {
  final service = createNfcService();
  ref.onDispose(service.dispose);
  return service;
});
