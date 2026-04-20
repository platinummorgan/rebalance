import 'package:flutter/foundation.dart';

/// No-op analytics service.
///
/// Privacy policy alignment:
/// - This app does not transmit analytics or telemetry.
/// - Calls are intentionally no-op to preserve existing call sites.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const bool _verboseLogs = false;

  void _trace(String message) {
    if (_verboseLogs && kDebugMode) {
      debugPrint('[Analytics] $message');
    }
  }

  /// No-op initializer kept for compatibility with startup wiring.
  Future<void> initialize() async {
    _trace('Disabled (no telemetry backend configured)');
  }

  /// Navigation observer is intentionally absent in privacy-first mode.
  Object? get observer => null;

  // ============================================================================
  // PRO CONVERSION FUNNEL TRACKING
  // ============================================================================

  Future<void> logProScreenView() async {
    _trace('Pro screen viewed');
  }

  Future<void> logProFeatureTap(String featureName) async {
    _trace('Pro feature tapped: $featureName');
  }

  Future<void> logUpgradeButtonTap({
    required String location,
    String? planType,
  }) async {
    _trace(
      'Upgrade button tapped at: $location${planType != null ? " ($planType)" : ""}',
    );
  }

  Future<void> logPurchaseStarted(String planType) async {
    _trace('Purchase started: $planType');
  }

  Future<void> logPurchaseSuccess({
    required String planType,
    required String purchaseId,
  }) async {
    _trace('Purchase success: $planType (ID: $purchaseId)');
  }

  Future<void> logPurchaseFailure({
    required String planType,
    required String errorCode,
    required String errorMessage,
  }) async {
    _trace(
      'Purchase failure: $planType - Code: $errorCode, Message: $errorMessage',
    );
  }

  Future<void> logPurchaseCancel(String planType) async {
    _trace('Purchase cancel: $planType');
  }

  // ============================================================================
  // FEATURE USAGE TRACKING
  // ============================================================================

  Future<void> logRetirementCalculatorView({required bool isPro}) async {
    _trace('Retirement Calculator viewed (Pro: $isPro)');
  }

  Future<void> logDebtOptimizerView({required bool isPro}) async {
    _trace('Debt Optimizer viewed (Pro: $isPro)');
  }

  Future<void> logRebalancingView({required bool isPro}) async {
    _trace('Rebalancing screen viewed (Pro: $isPro)');
  }

  Future<void> logScenarioEngineView({required bool isPro}) async {
    _trace('Scenario Engine viewed (Pro: $isPro)');
  }

  // ============================================================================
  // PRO BANNER TRACKING
  // ============================================================================

  Future<void> logProBannerView() async {
    _trace('Pro banner viewed');
  }

  Future<void> logProBannerTap() async {
    _trace('Pro banner tapped');
  }

  Future<void> logProBannerDismiss() async {
    _trace('Pro banner dismissed');
  }

  // ============================================================================
  // GUARDRAILS TRACKING
  // ============================================================================

  Future<void> logGuardrailsScreenView() async {
    _trace('Guardrails screen viewed');
  }

  Future<void> logGuardrailsSliderChange({
    required double additionalSpending,
    required double safeToSpend,
  }) async {
    final percentOfBudget =
        safeToSpend > 0 ? (additionalSpending / safeToSpend) * 100 : 0.0;
    _trace(
      'Guardrails slider changed: +\$${additionalSpending.toStringAsFixed(2)} (${percentOfBudget.toStringAsFixed(0)}%)',
    );
  }

  Future<void> logGuardrailsStateRed({
    required double shortage,
    required String dayName,
  }) async {
    _trace(
      'Guardrails RED state: short \$${shortage.toStringAsFixed(2)} by $dayName',
    );
  }

  Future<void> logGuardrailsStateYellow({
    required double bufferLeft,
  }) async {
    _trace(
      'Guardrails YELLOW state: tight with \$${bufferLeft.toStringAsFixed(2)} buffer',
    );
  }

  Future<void> logGuardrailsProBannerView() async {
    _trace('Guardrails Pro banner viewed');
  }

  Future<void> logProBannerClick() async {
    _trace('Pro banner clicked from guardrails');
  }

  // ============================================================================
  // USER PROPERTIES
  // ============================================================================

  Future<void> setUserProStatus(bool isPro) async {
    _trace('User property set: is_pro=$isPro');
  }

  Future<void> setUserId(String userId) async {
    _trace('User ID set: $userId');
  }

  // ============================================================================
  // APP LIFECYCLE EVENTS
  // ============================================================================

  Future<void> logAppOpen() async {
    _trace('App opened');
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    _trace('Screen view: $screenName');
  }
}
