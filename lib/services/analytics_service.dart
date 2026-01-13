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
      '[Analytics] Upgrade button tapped at: $location${planType != null ? " ($planType)" : ""}',
    );
  }

  /// Track when purchase is initiated (user taps buy button)
  Future<void> logPurchaseStarted(String planType) async {
    await _analytics?.logEvent(
      name: 'purchase_started',
      parameters: {
        'plan_type': planType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Purchase started: $planType');
  }

  /// Track when purchase completes successfully
  Future<void> logPurchaseSuccess({
    required String planType,
    required String purchaseId,
  }) async {
    await _analytics?.logEvent(
      name: 'purchase_success',
      parameters: {
        'plan_type': planType,
        'purchase_id': purchaseId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Purchase success: $planType (ID: $purchaseId)');
  }

  /// Track when purchase fails
  Future<void> logPurchaseFailure({
    required String planType,
    required String errorCode,
    required String errorMessage,
  }) async {
    await _analytics?.logEvent(
      name: 'purchase_failure',
      parameters: {
        'plan_type': planType,
        'error_code': errorCode,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint(
      '[Analytics] Purchase failure: $planType - Code: $errorCode, Message: $errorMessage',
    );
  }

  /// Track when user cancels purchase (normal behavior, not an error)
  Future<void> logPurchaseCancel(String planType) async {
    await _analytics?.logEvent(
      name: 'purchase_cancel',
      parameters: {
        'plan_type': planType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Purchase cancel: $planType');
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
  // GUARDRAILS TRACKING
  // ============================================================================

  /// Track when user views Weekly Guardrails screen
  Future<void> logGuardrailsScreenView() async {
    await _analytics?.logEvent(
      name: 'guardrails_screen_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Guardrails screen viewed');
  }

  /// Track when user adjusts the what-if slider
  Future<void> logGuardrailsSliderChange({
    required double additionalSpending,
    required double safeToSpend,
  }) async {
    final percentOfBudget =
        safeToSpend > 0 ? (additionalSpending / safeToSpend) * 100 : 0.0;
    await _analytics?.logEvent(
      name: 'guardrails_slider_change',
      parameters: {
        'additional_spending': additionalSpending,
        'percent_of_budget': percentOfBudget.round(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint(
      '[Analytics] Guardrails slider changed: +\$${additionalSpending.toStringAsFixed(2)} (${percentOfBudget.toStringAsFixed(0)}%)',
    );
  }

  /// Track when slider goes into red state (user would be short)
  Future<void> logGuardrailsStateRed({
    required double shortage,
    required String dayName,
  }) async {
    await _analytics?.logEvent(
      name: 'guardrails_state_red',
      parameters: {
        'shortage_amount': shortage,
        'shortage_day': dayName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint(
      '[Analytics] Guardrails RED state: short \$${shortage.toStringAsFixed(2)} by $dayName',
    );
  }

  /// Track when slider goes into yellow state (tight buffer)
  Future<void> logGuardrailsStateYellow({
    required double bufferLeft,
  }) async {
    await _analytics?.logEvent(
      name: 'guardrails_state_yellow',
      parameters: {
        'buffer_amount': bufferLeft,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint(
      '[Analytics] Guardrails YELLOW state: tight with \$${bufferLeft.toStringAsFixed(2)} buffer',
    );
  }

  /// Track when Pro upsell card is shown on guardrails screen
  Future<void> logGuardrailsProBannerView() async {
    await _analytics?.logEvent(
      name: 'guardrails_pro_banner_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Guardrails Pro banner viewed');
  }

  /// Track when user clicks Pro CTA from guardrails screen
  Future<void> logProBannerClick() async {
    await _analytics?.logEvent(
      name: 'pro_banner_click',
      parameters: {
        'source': 'guardrails',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('[Analytics] Pro banner clicked from guardrails');
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
