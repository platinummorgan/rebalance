import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/services/backup_crypto_service.dart';

void main() {
  group('BackupCryptoService', () {
    const passphrase = 'StrongPassphrase!123';

    test('encrypt/decrypt roundtrip succeeds', () async {
      final payload = jsonEncode(<String, dynamic>{
        'accounts': [
          {'id': '1', 'name': 'Checking', 'balance': 1000.0},
        ],
        'timestamp': '2026-03-26T00:00:00.000Z',
      });

      final encrypted = await BackupCryptoService.encryptJson(
        plaintextJson: payload,
        passphrase: passphrase,
      );
      final envelope = jsonDecode(encrypted) as Map<String, dynamic>;

      expect(BackupCryptoService.isEncryptedEnvelope(envelope), isTrue);

      final decrypted = await BackupCryptoService.decryptJson(
        encryptedEnvelope: envelope,
        passphrase: passphrase,
      );

      expect(decrypted, payload);
    });

    test('decrypt fails with incorrect passphrase', () async {
      final payload = jsonEncode(<String, dynamic>{'hello': 'world'});
      final encrypted = await BackupCryptoService.encryptJson(
        plaintextJson: payload,
        passphrase: passphrase,
      );
      final envelope = jsonDecode(encrypted) as Map<String, dynamic>;

      expect(
        () => BackupCryptoService.decryptJson(
          encryptedEnvelope: envelope,
          passphrase: 'WrongPassphrase!123',
        ),
        throwsA(anything),
      );
    });

    test('decrypt fails when ciphertext is tampered', () async {
      final payload = jsonEncode(<String, dynamic>{'x': 1});
      final encrypted = await BackupCryptoService.encryptJson(
        plaintextJson: payload,
        passphrase: passphrase,
      );
      final envelope = jsonDecode(encrypted) as Map<String, dynamic>;
      envelope['ciphertext'] = 'AAAA';

      expect(
        () => BackupCryptoService.decryptJson(
          encryptedEnvelope: envelope,
          passphrase: passphrase,
        ),
        throwsA(anything),
      );
    });
  });
}
