import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class EntitlementVerificationResult {
  final bool isValid;
  final bool isPro;
  final bool isLifetime;
  final String status;
  final DateTime? expiresAt;
  final String? productId;

  const EntitlementVerificationResult({
    required this.isValid,
    required this.isPro,
    required this.isLifetime,
    required this.status,
    required this.expiresAt,
    required this.productId,
  });
}

class EntitlementBackendService {
  static const String _baseUrl = String.fromEnvironment(
    'ENTITLEMENT_API_BASE_URL',
    defaultValue: '',
  );
  static const String _apiKey = String.fromEnvironment(
    'ENTITLEMENT_API_KEY',
    defaultValue: '',
  );
  static const String _appUserIdKey = 'wealth_dial_app_user_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_apiKey.trim().isNotEmpty) {
      headers['X-Entitlement-Api-Key'] = _apiKey;
    }
    return headers;
  }

  Future<String> getOrCreateAppUserId() async {
    final existing = await _storage.read(key: _appUserIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = const Uuid().v4();
    await _storage.write(key: _appUserIdKey, value: created);
    return created;
  }

  Future<EntitlementVerificationResult?> verifyGooglePlayPurchase(
    PurchaseDetails purchase,
  ) async {
    if (!isConfigured) return null;

    try {
      final appUserId = await getOrCreateAppUserId();
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/v1/verify/google-play'),
            headers: _headers,
            body: jsonEncode({
              'appUserId': appUserId,
              'productId': purchase.productID,
              'purchaseToken': purchase.verificationData.serverVerificationData,
              'packageName': packageName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[EntitlementBackend] Verification failed: ${response.statusCode} ${parsed['error'] ?? parsed['message']}',
        );
        return const EntitlementVerificationResult(
          isValid: false,
          isPro: false,
          isLifetime: false,
          status: 'verification_rejected',
          expiresAt: null,
          productId: null,
        );
      }

      final entitlement = parsed['entitlement'] as Map<String, dynamic>? ?? {};
      return EntitlementVerificationResult(
        isValid: parsed['verified'] == true,
        isPro: entitlement['isPro'] == true,
        isLifetime: entitlement['isLifetime'] == true,
        status: entitlement['status'] as String? ?? 'unknown',
        expiresAt: _parseDate(entitlement['expiresAt']),
        productId: entitlement['productId'] as String?,
      );
    } catch (error) {
      debugPrint('[EntitlementBackend] Verification request failed: $error');
      return const EntitlementVerificationResult(
        isValid: false,
        isPro: false,
        isLifetime: false,
        status: 'verification_error',
        expiresAt: null,
        productId: null,
      );
    }
  }

  Future<EntitlementVerificationResult?> fetchCurrentEntitlement() async {
    if (!isConfigured) return null;

    try {
      final appUserId = await getOrCreateAppUserId();
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v1/entitlements/$appUserId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        return const EntitlementVerificationResult(
          isValid: true,
          isPro: false,
          isLifetime: false,
          status: 'inactive',
          expiresAt: null,
          productId: null,
        );
      }

      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[EntitlementBackend] Fetch entitlement failed: ${response.statusCode} ${parsed['error'] ?? parsed['message']}',
        );
        return null;
      }

      final entitlement = parsed['entitlement'] as Map<String, dynamic>? ?? {};
      return EntitlementVerificationResult(
        isValid: true,
        isPro: entitlement['isPro'] == true,
        isLifetime: entitlement['isLifetime'] == true,
        status: entitlement['status'] as String? ?? 'unknown',
        expiresAt: _parseDate(entitlement['expiresAt']),
        productId: entitlement['productId'] as String?,
      );
    } catch (error) {
      debugPrint('[EntitlementBackend] Fetch entitlement request failed: $error');
      return null;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
