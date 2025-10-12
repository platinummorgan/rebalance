import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../data/models.dart';

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

    debugPrint('PurchaseService: loadProducts start');
    final response = await _iap!.queryProductDetails(_productIds);

    if (response.error != null) {
      throw Exception('Failed to load products: ${response.error!.message}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    debugPrint(
      'PurchaseService: loadProducts finished, found: ${response.productDetails.map((p) => p.id).toList()}',
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
  Future<void> restorePurchases(Ref ref) async {
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
        }

        // Mark purchase as complete
        if (purchase.pendingCompletePurchase) {
          if (_iap != null) {
            await _iap!.completePurchase(purchase);
          }
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
        // Handle error (show message to user)
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

    // Update settings to enable Pro
    final currentSettings = ref.read(settingsProvider).valueOrNull;
    if (currentSettings == null) {
      debugPrint('Cannot grant Pro: Settings not loaded');
      return;
    }

    // Create a NEW Settings object with isPro = true so Riverpod detects the change
    final updatedSettings = Settings(
      riskBand: currentSettings.riskBand,
      monthlyEssentials: currentSettings.monthlyEssentials,
      driftThresholdPct: currentSettings.driftThresholdPct,
      notificationsEnabled: currentSettings.notificationsEnabled,
      usEquityTargetPct: currentSettings.usEquityTargetPct,
      isPro: true, // <-- Grant Pro access
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
    );

    // Save updated settings
    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

    debugPrint('Pro access granted!');
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
    );

    await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);
    debugPrint('Pro granted via grantProForTesting');
  }

  /// Check if user has active subscription or lifetime purchase
  Future<bool> hasActiveSubscription() async {
    if (!await isAvailable()) {
      return false;
    }

    // For now, rely on local isPro flag
    // In production, you'd query Google Play for active subscriptions
    return true; // Placeholder - implement server-side verification
  }
}

/// Provider for purchase service
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(() => service.dispose());
  return service;
});
