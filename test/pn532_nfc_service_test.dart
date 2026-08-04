import 'package:everafter/services/pn532_nfc_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a libnfc NFCID1 UID', () {
    expect(
      parsePn532Uid('    UID (NFCID1): 04  00  00  00  00  fe'),
      '04:00:00:00:00:FE',
    );
  });

  test('rejects unrelated and malformed libnfc output', () {
    expect(parsePn532Uid('NFC reader: PN532 opened'), isNull);
    expect(parsePn532Uid('UID (NFCID1): 04 a7'), isNull);
  });
}
