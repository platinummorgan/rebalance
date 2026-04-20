import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

class BackupCryptoService {
  static const String envelopeFormat = 'wd_backup_encrypted_v1';
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _pbkdf2Iterations = 150000;

  static final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: 256,
  );

  static final AesGcm _cipher = AesGcm.with256bits();
  static final Random _random = Random.secure();

  static bool isEncryptedEnvelope(Map<String, dynamic> data) {
    return data['format'] == envelopeFormat &&
        data['kdf'] is Map<String, dynamic> &&
        data['cipher'] is Map<String, dynamic> &&
        data['ciphertext'] is String &&
        data['mac'] is String;
  }

  static Future<String> encryptJson({
    required String plaintextJson,
    required String passphrase,
  }) async {
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final secretKey = await _kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintextJson),
      secretKey: secretKey,
      nonce: nonce,
    );
    final checksum =
        crypto.sha256.convert(utf8.encode(plaintextJson)).toString();

    final envelope = <String, dynamic>{
      'format': envelopeFormat,
      'createdAt': DateTime.now().toIso8601String(),
      'plaintextSha256': checksum,
      'kdf': <String, dynamic>{
        'name': 'PBKDF2-HMAC-SHA256',
        'iterations': _pbkdf2Iterations,
        'salt': base64Encode(salt),
      },
      'cipher': <String, dynamic>{
        'name': 'AES-256-GCM',
        'nonce': base64Encode(secretBox.nonce),
      },
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  static Future<String> decryptJson({
    required Map<String, dynamic> encryptedEnvelope,
    required String passphrase,
  }) async {
    if (!isEncryptedEnvelope(encryptedEnvelope)) {
      throw const FormatException('Invalid encrypted backup envelope');
    }

    final kdfData = encryptedEnvelope['kdf'] as Map<String, dynamic>;
    final cipherData = encryptedEnvelope['cipher'] as Map<String, dynamic>;
    final iterations = (kdfData['iterations'] as num?)?.toInt();
    if (iterations == null || iterations <= 0) {
      throw const FormatException('Invalid KDF iteration count');
    }

    final salt = base64Decode(kdfData['salt'] as String);
    final nonce = base64Decode(cipherData['nonce'] as String);
    final cipherText = base64Decode(encryptedEnvelope['ciphertext'] as String);
    final macBytes = base64Decode(encryptedEnvelope['mac'] as String);

    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final secretKey = await kdf.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );

    final clearBytes = await _cipher.decrypt(
      SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      ),
      secretKey: secretKey,
    );

    final decryptedJson = utf8.decode(clearBytes);
    final expectedChecksum = encryptedEnvelope['plaintextSha256'] as String?;
    if (expectedChecksum != null && expectedChecksum.isNotEmpty) {
      final actualChecksum =
          crypto.sha256.convert(utf8.encode(decryptedJson)).toString();
      if (actualChecksum != expectedChecksum) {
        throw const FormatException(
          'Backup integrity check failed. The file may be corrupted or modified.',
        );
      }
    }

    return decryptedJson;
  }

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}
