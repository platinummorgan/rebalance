import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking user behavior and Pro conversion funnel
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      debugPrint('[Analytics] Initialized successfully');
    } catch (e) {
      debugPrint('[Analytics] Failed to initialize: $e');
    }
  }

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  // ============================================================================
  // PRO CONVERSION FUNNEL TRACKING
  // ============================================================================

  /// Track when user views Pro features screen
  Future<void> logProScreenView() async {
    await _analytics?.logEvent(
      name: 'pro_screen_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Pro screen viewed');
  }

  /// Track when user taps a locked Pro feature
  Future<void> logProFeatureTap(String featureName) async {
    await _analytics?.logEvent(
      name: 'pro_feature_tap',
      parameters: {
        'feature_name': featureName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Pro feature tapped: $featureName');
  }

  /// Track when user taps "Upgrade to Pro" button
  Future<void> logUpgradeButtonTap({
    required String
        location, // e.g., 'pro_screen', 'retirement_calculator', 'debt_optimizer'
    String? planType, // e.g., 'monthly', 'annual', 'lifetime'
  }) async {
    await _analytics?.logEvent(
      name: 'upgrade_button_tap',
      parameters: {
        'location': location,
        if (planType != null) 'plan_type': planType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint(
        '[Analytics] Upgrade button tapped at: $location${planType != null ? " ($planType)" : ""}',);
  }

  /// Track when purchase flow starts (Google Play billing sheet opens)
  Future<void> logPurchaseFlowStart(String planType) async {
    await _analytics?.logEvent(
      name: 'purchase_flow_start',
      parameters: {
        'plan_type': planType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Purchase flow started: $planType');
  }

  /// Track when purchase completes successfully
  Future<void> logPurchaseComplete({
    required String planType,
    required double price,
    required String currency,
  }) async {
    await _analytics?.logEvent(
      name: 'purchase_complete',
      parameters: {
        'plan_type': planType,
        'price': price,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    await _analytics?.logPurchase(
      value: price,
      currency: currency,
      items: [
        AnalyticsEventItem(
          itemName: 'pro_subscription',
          itemId: planType,
          price: price,
          quantity: 1,
        ),
      ],
    );
    debugPrint(
        '[Analytics] Purchase completed: $planType (\$$price $currency)',);
  }

  /// Track when purchase fails
  Future<void> logPurchaseFailure({
    required String planType,
    required String errorMessage,
  }) async {
    await _analytics?.logEvent(
      name: 'purchase_failure',
      parameters: {
        'plan_type': planType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Purchase failed: $planType - $errorMessage');
  }

  // ============================================================================
  // FEATURE USAGE TRACKING
  // ============================================================================

  /// Track when user views Retirement Calculator (Pro feature)
  Future<void> logRetirementCalculatorView({required bool isPro}) async {
    await _analytics?.logEvent(
      name: 'retirement_calculator_view',
      parameters: {
        'is_pro': isPro,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Retirement Calculator viewed (Pro: $isPro)');
  }

  /// Track when user views Debt Optimizer (Pro feature)
  Future<void> logDebtOptimizerView({required bool isPro}) async {
    await _analytics?.logEvent(
      name: 'debt_optimizer_view',
      parameters: {
        'is_pro': isPro,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Debt Optimizer viewed (Pro: $isPro)');
  }

  /// Track when user views Rebalancing screen (Pro feature)
  Future<void> logRebalancingView({required bool isPro}) async {
    await _analytics?.logEvent(
      name: 'rebalancing_view',
      parameters: {
        'is_pro': isPro,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Rebalancing screen viewed (Pro: $isPro)');
  }

  /// Track when user views Scenario Engine (Pro feature)
  Future<void> logScenarioEngineView({required bool isPro}) async {
    await _analytics?.logEvent(
      name: 'scenario_engine_view',
      parameters: {
        'is_pro': isPro,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Scenario Engine viewed (Pro: $isPro)');
  }

  // ============================================================================
  // PRO BANNER TRACKING
  // ============================================================================

  /// Track when Pro banner is shown on dashboard
  Future<void> logProBannerView() async {
    await _analytics?.logEvent(
      name: 'pro_banner_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Pro banner viewed');
  }

  /// Track when user taps Pro banner CTA
  Future<void> logProBannerTap() async {
    await _analytics?.logEvent(
      name: 'pro_banner_tap',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Pro banner tapped');
  }

  /// Track when user dismisses Pro banner
  Future<void> logProBannerDismiss() async {
    await _analytics?.logEvent(
      name: 'pro_banner_dismiss',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Pro banner dismissed');
  }

  // ============================================================================
  // USER PROPERTIES
  // ============================================================================

  /// Set user property for Pro status
  Future<void> setUserProStatus(bool isPro) async {
    await _analytics?.setUserProperty(
      name: 'is_pro',
      value: isPro.toString(),
    );
    debugPrint('[Analytics] User property set: is_pro=$isPro');
  }

  /// Set user ID (for cross-device tracking)
  Future<void> setUserId(String userId) async {
    await _analytics?.setUserId(id: userId);
    debugPrint('[Analytics] User ID set: $userId');
  }

  // ============================================================================
  // APP LIFECYCLE EVENTS
  // ============================================================================

  /// Track app open
  Future<void> logAppOpen() async {
    await _analytics?.logAppOpen();
    debugPrint('[Analytics] App opened');
  }

  /// Track screen view (generic)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    debugPrint('[Analytics] Screen view: $screenName');
  }
}
