import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../data/models.dart';
import 'analytics_service.dart';

/// Service for handling in-app purchases and subscriptions
class PurchaseService {
  // Only access InAppPurchase.instance on supported platforms
  static InAppPurchase? get _iap => kIsWeb ? null : InAppPurchase.instance;

  // Product IDs - must match exactly what you create in Google Play Console
  static const String monthlySubId = 'pro_monthly';
  static const String annualSubId = 'pro_annual';
  static const String lifetimeId = 'founder_lifetime';

  static const Set<String> _productIds = {
    monthlySubId,
    annualSubId,
    lifetimeId,
  };

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Initialize the purchase service and listen for purchase updates
  Future<void> initialize(Ref ref) async {
    debugPrint('PurchaseService: initialize called');

    // Skip initialization on web platform (IAP not supported)
    if (_iap == null) {
      debugPrint('PurchaseService: Skipping initialization on web platform');
      return;
    }

    try {
      // Listen to purchase updates
      _subscription = _iap!.purchaseStream.listen(
        (purchases) => _handlePurchaseUpdates(purchases, ref),
        onError: (error) {
          debugPrint('Purchase stream error: $error');
        },
      );
      debugPrint('PurchaseService: Initialized successfully');
    } catch (e) {
      debugPrint('PurchaseService: Initialize error (non-fatal): $e');
      // Don't rethrow - let the app continue even if IAP fails
    }
  }

  /// Clean up subscription when service is disposed
  void dispose() {
    _subscription?.cancel();
  }

  /// Check if in-app purchases are available on this device
  Future<bool> isAvailable() async {
    if (_iap == null) return false;
    return await _iap!.isAvailable();
  }

  /// Load available products from the store
  Future<List<ProductDetails>> loadProducts() async {
    if (_iap == null) {
      throw Exception('In-app purchases not supported on this platform');
    }

    if (!await isAvailable()) {
      throw Exception('In-app purchases not available');
    }

    debugPrint('PurchaseService: loadProducts start - querying: $_productIds');
    final response = await _iap!.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint(
        'PurchaseService: queryProductDetails ERROR: ${response.error!.code} - ${response.error!.message}',
      );
      throw Exception('Failed to load products: ${response.error!.message}');
    }

    debugPrint(
      'PurchaseService: Products found: ${response.productDetails.map((p) => p.id).toList()}',
    );

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'PurchaseService: Products NOT FOUND in Play Store: ${response.notFoundIDs}',
      );
      debugPrint(
        'PurchaseService: These product IDs must be created in Google Play Console',
      );
    }

    debugPrint(
      'PurchaseService: loadProducts finished, returning ${response.productDetails.length} products',
    );
    return response.productDetails;
  }

  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    if (_iap == null) {
      debugPrint('Purchase error: IAP not supported on this platform');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      debugPrint('PurchaseService: purchaseProduct called for ${product.id}');
      // For subscriptions, use buyNonConsumable
      // For one-time purchases (lifetime), also use buyNonConsumable
      final success =
          await _iap!.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases (important for reinstalls)
  Future<void> restorePurchases() async {
    if (_iap == null) {
      debugPrint(
        'Restore purchases skipped: IAP not supported on this platform',
      );
      return;
    }

    try {
      await _iap!.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      rethrow;
    }
  }

  /// Handle purchase updates from the stream
  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    Ref ref,
  ) async {
    for (final purchase in purchases) {
      debugPrint('Purchase update: ${purchase.productID} - ${purchase.status}');

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify purchase (in production, verify with your backend)
        final valid = await _verifyPurchase(purchase);

        if (valid) {
          // Grant Pro access
          await _grantProAccess(ref, purchase.productID);

          // Track successful purchase
          try {
            final analyticsService = AnalyticsService();
            await analyticsService.logPurchaseSuccess(
              planType: purchase.productID,
              purchaseId: purchase.purchaseID ?? 'unknown',
            );
          } catch (e) {
            debugPrint('Failed to log purchase success analytics: $e');
          }
        }

        // Mark purchase as complete
        if (purchase.pendingCompletePurchase) {
          if (_iap != null) {
            await _iap!.completePurchase(purchase);
          }
        }
      } else if (purchase.status == PurchaseStatus.error) {
        // Enhanced error logging
        final errorCode = purchase.error?.code ?? 'UNKNOWN';
        final errorMessage = purchase.error?.message ?? 'No error message';
        final errorDetails = purchase.error?.details ?? 'No details';

        debugPrint('❌ PURCHASE ERROR DETAILS:');
        debugPrint('  Product ID: ${purchase.productID}');
        debugPrint('  Error Code: $errorCode');
        debugPrint('  Error Message: $errorMessage');
        debugPrint('  Error Details: $errorDetails');
        debugPrint('  Purchase ID: ${purchase.purchaseID}');
        debugPrint('  Transaction Date: ${purchase.transactionDate}');

        // Log to Firebase Analytics with detailed error info
        try {
          final analyticsService = AnalyticsService();
          await analyticsService.logPurchaseFailure(
            planType: purchase.productID,
            errorCode: errorCode,
            errorMessage: '$errorMessage | Details: $errorDetails',
          );
        } catch (e) {
          debugPrint('Failed to log analytics: $e');
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        // User cancelled the purchase - log to analytics
        debugPrint('Purchase cancelled by user: ${purchase.productID}');

        try {
          final analyticsService = AnalyticsService();
          await analyticsService.logPurchaseCancel(purchase.productID);
        } catch (e) {
          debugPrint('Failed to log purchase cancellation: $e');
        }
      } else if (purchase.status == PurchaseStatus.pending) {
        debugPrint(
          'Purchase pending (awaiting payment): ${purchase.productID}',
        );
      }
    }
  }

  /// Verify the purchase (simplified - in production, verify server-side)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: In production, send purchase.verificationData to your backend
    // for server-side verification with Google Play
    // For now, we trust the local purchase
    return true;
  }

  /// Grant Pro access to the user
  Future<void> _grantProAccess(Ref ref, String productId) async {
    debugPrint('Granting Pro access for: $productId');

    // Wait for settings to load if not ready yet (race condition fix)
    final currentSettings = await _waitForSettings(ref);
    if (currentSettings == null) {
      debugPrint('Cannot grant Pro: Settings failed to load after waiting');
      return;
    }

    // Extend from existing expiry when renewing; otherwise start from now
    final now = DateTime.now();
    final baseDate = (currentSettings.proExpiryDate != null &&
            currentSettings.proExpiryDate!.isAfter(now))
        ? currentSettings.proExpiryDate!
        : now;

    // Calculate expiry date based on product type
    DateTime? expiryDate;
    if (productId == monthlySubId) {
      expiryDate = baseDate.add(const Duration(days: 31));
    } else if (productId == annualSubId) {
      expiryDate = baseDate.add(const Duration(days: 366));
    }
    // Lifetime has no expiry (null)

    debugPrint(
      'Setting Pro expiry: ${expiryDate?.toIso8601String() ?? "lifetime"}',
    );

    // Create a NEW Settings object with isPro = true so Riverpod detects the change
    final updatedSettings = Settings(
      riskBand: currentSettings.riskBand,
      monthlyEssentials: currentSettings.monthlyEssentials,
      driftThresholdPct: currentSettings.driftThresholdPct,
      notificationsEnabled: currentSettings.notificationsEnabled,
      usEquityTargetPct: currentSettings.usEquityTargetPct,
      isPro: true, // <-- Grant Pro access
      proExpiryDate: expiryDate, // <-- Store expiry date
      biometricLockEnabled: currentSettings.biometricLockEnabled,
      darkModeEnabled: currentSettings.darkModeEnabled,
      colorTheme: currentSettings.colorTheme,
      liquidityBondHaircut: currentSettings.liquidityBondHaircut,
      bucketCap: currentSettings.bucketCap,
      employerStockThreshold: currentSettings.employerStockThreshold,
      monthlyIncome: currentSettings.monthlyIncome,
      incomeMultiplierFallback: currentSettings.incomeMultiplierFallback,
      schemaVersion: currentSettings.schemaVersion,
      concentrationRiskSnoozedUntil:
          currentSettings.concentrationRiskSnoozedUntil,
      concentrationRiskResolvedAt: currentSettings.concentrationRiskResolvedAt,
      homeCountry: currentSettings.homeCountry,
      globalDiversificationMode: currentSettings.globalDiversificationMode,
      intlTargetOverride: currentSettings.intlTargetOverride,
      intlTolerancePct: currentSettings.intlTolerancePct,
      intlFloorPct: currentSettings.intlFloorPct,
      intlPenaltyScale: currentSettings.intlPenaltyScale,
      financialHealthBaseline: currentSettings.financialHealthBaseline,
      financialHealthGlobalScale: currentSettings.financialHealthGlobalScale,
      currency: currentSettings.currency,
      baseCurrency: currentSettings.baseCurrency,
      language: currentSettings.language, // Keep existing language
    );

    // Save updated settings
    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

    debugPrint('Pro access granted!');
  }

  /// Wait for settings to be loaded (handles race condition on app startup)
  Future<Settings?> _waitForSettings(Ref ref) async {
    for (int i = 0; i < 10; i++) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings != null) {
        return settings;
      }
      debugPrint(
        '_grantProAccess: Waiting for settings to load... attempt ${i + 1}/10',
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  /// Developer helper to grant Pro locally (useful for testing when you own the product)
  /// This should never be used in production code paths other than testing/debug builds.
  Future<void> grantProForTesting(Ref ref) async {
    final currentSettings = ref.read(settingsProvider).valueOrNull;
    if (currentSettings == null) {
      debugPrint('Cannot grant Pro for testing: Settings not loaded');
      return;
    }

    // Create a NEW Settings object with isPro = true so Riverpod detects the change
    final updatedSettings = Settings(
      riskBand: currentSettings.riskBand,
      monthlyEssentials: currentSettings.monthlyEssentials,
      driftThresholdPct: currentSettings.driftThresholdPct,
      notificationsEnabled: currentSettings.notificationsEnabled,
      usEquityTargetPct: currentSettings.usEquityTargetPct,
      isPro: true, // <-- Grant Pro access for testing
      biometricLockEnabled: currentSettings.biometricLockEnabled,
      darkModeEnabled: currentSettings.darkModeEnabled,
      colorTheme: currentSettings.colorTheme,
      liquidityBondHaircut: currentSettings.liquidityBondHaircut,
      bucketCap: currentSettings.bucketCap,
      employerStockThreshold: currentSettings.employerStockThreshold,
      monthlyIncome: currentSettings.monthlyIncome,
      incomeMultiplierFallback: currentSettings.incomeMultiplierFallback,
      schemaVersion: currentSettings.schemaVersion,
      concentrationRiskSnoozedUntil:
          currentSettings.concentrationRiskSnoozedUntil,
      concentrationRiskResolvedAt: currentSettings.concentrationRiskResolvedAt,
      homeCountry: currentSettings.homeCountry,
      globalDiversificationMode: currentSettings.globalDiversificationMode,
      intlTargetOverride: currentSettings.intlTargetOverride,
      intlTolerancePct: currentSettings.intlTolerancePct,
      intlFloorPct: currentSettings.intlFloorPct,
      intlPenaltyScale: currentSettings.intlPenaltyScale,
      financialHealthBaseline: currentSettings.financialHealthBaseline,
      financialHealthGlobalScale: currentSettings.financialHealthGlobalScale,
      currency: currentSettings.currency,
      baseCurrency: currentSettings.baseCurrency,
      language: currentSettings.language, // Keep existing language
    );

    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);
    debugPrint('Pro granted via grantProForTesting');
  }

  /// Check if user has active subscription or lifetime purchase
  Future<bool> hasActiveSubscription(Ref ref) async {
    final settings = await _waitForSettings(ref);
    if (settings == null || !settings.isPro) return false;

    // If no expiry date, it's lifetime (always active)
    if (settings.proExpiryDate == null) return true;

    // Check if subscription has expired
    final now = DateTime.now();
    if (settings.proExpiryDate!.isBefore(now)) {
      // Subscription expired - revoke Pro access
      debugPrint('Subscription expired on ${settings.proExpiryDate}');
      await _revokeProAccess(ref);
      return false;
    }

    return true;
  }

  /// Revoke Pro access when subscription expires
  Future<void> _revokeProAccess(Ref ref) async {
    debugPrint('Revoking Pro access due to expiry');

    final currentSettings = await _waitForSettings(ref);
    if (currentSettings == null) return;

    final updatedSettings = Settings(
      riskBand: currentSettings.riskBand,
      monthlyEssentials: currentSettings.monthlyEssentials,
      driftThresholdPct: currentSettings.driftThresholdPct,
      notificationsEnabled: currentSettings.notificationsEnabled,
      usEquityTargetPct: currentSettings.usEquityTargetPct,
      isPro: false, // <-- Revoke Pro access
      proExpiryDate: null, // Clear expiry
      biometricLockEnabled: currentSettings.biometricLockEnabled,
      darkModeEnabled: currentSettings.darkModeEnabled,
      colorTheme: currentSettings.colorTheme,
      liquidityBondHaircut: currentSettings.liquidityBondHaircut,
      bucketCap: currentSettings.bucketCap,
      employerStockThreshold: currentSettings.employerStockThreshold,
      monthlyIncome: currentSettings.monthlyIncome,
      incomeMultiplierFallback: currentSettings.incomeMultiplierFallback,
      schemaVersion: currentSettings.schemaVersion,
      concentrationRiskSnoozedUntil:
          currentSettings.concentrationRiskSnoozedUntil,
      concentrationRiskResolvedAt: currentSettings.concentrationRiskResolvedAt,
      homeCountry: currentSettings.homeCountry,
      globalDiversificationMode: currentSettings.globalDiversificationMode,
      intlTargetOverride: currentSettings.intlTargetOverride,
      intlTolerancePct: currentSettings.intlTolerancePct,
      intlFloorPct: currentSettings.intlFloorPct,
      intlPenaltyScale: currentSettings.intlPenaltyScale,
      financialHealthBaseline: currentSettings.financialHealthBaseline,
      financialHealthGlobalScale: currentSettings.financialHealthGlobalScale,
      currency: currentSettings.currency,
      baseCurrency: currentSettings.baseCurrency,
      language: currentSettings.language,
    );

    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);
    debugPrint('Pro access revoked');
  }
}

/// Provider for purchase service
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(() => service.dispose());
  return service;
});
