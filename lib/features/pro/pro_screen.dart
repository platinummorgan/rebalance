import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../services/purchase_service.dart';
import '../../services/analytics_service.dart';
import '../../data/models.dart';
import '../../routes.dart' show AppRouter;
import '../../widgets/currency_text.dart';
import '../../generated/app_localizations.dart';

/// Outcome-focused Pro screen showing real financial impact
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  @override
  void initState() {
    super.initState();
    // Track Pro screen view when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logProScreenView();
    });
  }

  /// Get localized pricing based on user's currency setting
  Map<String, dynamic> _getPricing(String currencyCode) {
    switch (currencyCode) {
      case 'INR':
        return {
          'monthly': '₹249',
          'annual': '₹2,490',
          'lifetime': '₹3,299',
          'savings': '₹498',
        };
      case 'BDT':
        return {
          'monthly': '৳299',
          'annual': '৳2,990',
          'lifetime': '৳3,990',
          'savings': '৳598',
        };
      case 'SDG': // Sudanese Pound
        return {
          'monthly': 'SDG 2,400',
          'annual': 'SDG 14,400',
          'lifetime': 'SDG 24,000',
          'savings': 'SDG 14,400',
        };
      case 'IRR': // Iranian Rial
        return {
          'monthly': '۱۶۸,۰۰۰ ﷼',
          'annual': '۱,۰۰۸,۰۰۰ ﷼',
          'lifetime': '۱,۶۸۰,۰۰۰ ﷼',
          'savings': '۱,۰۰۸,۰۰۰ ﷼',
        };
      case 'EUR':
        return {
          'monthly': '€3.99',
          'annual': '€39.99',
          'lifetime': '€49.99',
          'savings': '€8',
        };
      case 'GBP':
        return {
          'monthly': '£3.49',
          'annual': '£34.99',
          'lifetime': '£44.99',
          'savings': '£7',
        };
      case 'USD':
      default:
        return {
          'monthly': '\$3.99',
          'annual': '\$23.99',
          'lifetime': '\$39.99',
          'savings': '\$24',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final liabilitiesAsync = ref.watch(liabilitiesProvider);

    final isPro = settingsAsync.value?.isPro ?? false;
    final accounts = accountsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Account>[],
    );
    final liabilities = liabilitiesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Liability>[],
    );

    if (isPro) {
      return _buildProActiveScreen(context);
    }

    return _buildUpgradeScreen(context, accounts, liabilities, ref);
  }

  Widget _buildProActiveScreen(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.proFeatures),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success badge
            const SizedBox(height: 24),

            Text(
              loc.yourProFeatures,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Feature cards with outcomes
            _buildActiveFeatureCard(
              context,
              icon: Icons.account_balance_wallet,
              title: loc.debtPayoffOptimizer,
              description: loc.debtPayoffDescription,
              stat: loc.saveThousands,
              color: Colors.blue,
              onTap: () => context.push(AppRouter.debtOptimizer),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.trending_up,
              title: loc.rebalancingAutopilot,
              description: loc.rebalancingDescription,
              stat: loc.reduceRisk,
              color: Colors.purple,
              onTap: () => context.push(AppRouter.rebalancing),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.psychology,
              title: loc.whatIfScenarioEngine,
              description: loc.whatIfDescription,
              stat: loc.seeProbability,
              color: Colors.orange,
              onTap: () => context.push(AppRouter.scenario),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.notifications_active,
              title: loc.customAlerts,
              description: loc.customAlertsDescription,
              stat: loc.knowImpact,
              color: Colors.red,
              onTap: () => context.push(AppRouter.customAlerts),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.calculate,
              title: loc.taxSmartAllocation,
              description: loc.taxSmartDescription,
              stat: loc.saveTaxes,
              color: Colors.teal,
              onTap: () => context.push(AppRouter.taxSmart),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.trending_up,
              title: loc.retirementCalculator,
              description: loc.retirementDescription,
              stat: loc.seeProbability,
              color: Colors.deepOrange,
              onTap: () => context.push(AppRouter.retirementCalculator),
            ),

            const SizedBox(height: 24),

            // Plan details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.planDetails,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.proActive,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String stat,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(description),
              const SizedBox(height: 4),
              Text(
                stat,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildUpgradeScreen(
    BuildContext context,
    List<Account> accounts,
    List<Liability> liabilities,
    WidgetRef ref,
  ) {
    final loc = AppLocalizations.of(context)!;
    // Calculate personalized savings
    final personalizedStats = _calculateRealImpact(
      accounts,
      liabilities,
      ref,
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.unlockPro),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with personalized savings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.diamond,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.rebalancePro,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Personalized hero stat
                  if (personalizedStats['hasData'] as bool) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.basedOnYourPortfolio,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            personalizedStats['heroText'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      loc.saveMoneyReduceRisk,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),

            // Outcome-focused features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Feature cards with specific outcomes
                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: loc.debtPayoffOptimizer,
                    personalizedValue: personalizedStats['debtSavings'],
                    genericOutcome: loc.debtPayoffDescription,
                    description: loc.compareStrategies,
                    color: Colors.blue,
                    onTap: () => context.push(AppRouter.debtOptimizer),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.trending_up,
                    title: loc.rebalancingAutopilot,
                    personalizedValue:
                        personalizedStats['concentrationRisk'] as String?,
                    genericOutcome: loc.rebalancingDescription,
                    description: loc.getSpecificTrades,
                    color: Colors.purple,
                    onTap: () => context.push(AppRouter.rebalancing),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.psychology,
                    title: loc.whatIfScenarioEngine,
                    personalizedValue: null,
                    genericOutcome: loc.whatIfDescription,
                    description: loc.monteCarloSimulation,
                    color: Colors.orange,
                    onTap: () => context.push(AppRouter.scenario),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.notifications_active,
                    title: loc.customAlertsWithContext,
                    personalizedValue: null,
                    genericOutcome: loc.customAlertsDescription,
                    description: loc.customThresholds,
                    color: Colors.red,
                    onTap: () => context.push(AppRouter.customAlerts),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.calculate,
                    title: loc.taxSmartAllocation,
                    personalizedValue: null,
                    genericOutcome: loc.taxSmartDescription,
                    description: loc.optimizeAccounts,
                    color: Colors.teal,
                    onTap: () => context.push(AppRouter.taxSmart),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.trending_up,
                    title: loc.retirementCalculator,
                    personalizedValue: null,
                    genericOutcome: loc.retirementDescription,
                    description: loc.projectRetirement,
                    color: Colors.deepOrange,
                    onTap: () => context.push(AppRouter.retirementCalculator),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.bar_chart,
                    title: loc.advancedPortfolioAnalytics,
                    personalizedValue: null,
                    genericOutcome: loc.advancedAnalyticsDescription,
                    description: loc.hhiConcentration,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 24),

                  // Pricing cards
                  Text(
                    loc.choosePlan,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Get localized pricing
                  Builder(
                    builder: (context) {
                      final settingsAsync = ref.watch(settingsProvider);
                      final currency = settingsAsync.maybeWhen(
                        data: (settings) => settings.currency,
                        orElse: () => 'USD',
                      );
                      final pricing = _getPricing(currency);

                      return Column(
                        children: [
                          _buildPricingCard(
                            context,
                            ref: ref,
                            title: loc.proMonthly,
                            price: pricing['monthly'],
                            period: loc.perMonth,
                            features: [
                              loc.allProFeatures,
                              loc.cancelAnytime,
                              loc.freeTrialDays,
                            ],
                            recommended: false,
                          ),
                          const SizedBox(height: 12),
                          _buildPricingCard(
                            context,
                            ref: ref,
                            title: loc.annual,
                            price: pricing['annual'],
                            period: loc.perYear,
                            badge: loc.bestValue,
                            features: [
                              loc.allProFeatures,
                              '${loc.save} ${pricing['savings']}',
                              loc.freeTrialDays,
                            ],
                            recommended: true,
                          ),
                          const SizedBox(height: 12),
                          _buildPricingCard(
                            context,
                            ref: ref,
                            title: loc.founderLifetime,
                            price: pricing['lifetime'],
                            period: loc.oneTime,
                            badge: loc.limited,
                            features: [
                              loc.everythingForever,
                              loc.firstFounders,
                              loc.priceIncreasesAfter,
                            ],
                            recommended: false,
                            isFounder: true,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Trust signals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildTrustItem(
                          context,
                          Icons.verified_user,
                          loc.privacy100,
                          loc.dataOnDevice,
                        ),
                        const SizedBox(height: 12),
                        _buildTrustItem(
                          context,
                          Icons.lock,
                          loc.encryptedStorage,
                          loc.bankGrade,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required dynamic personalizedValue,
    required String genericOutcome,
    required String description,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        personalizedValue is Map
                            ? Row(
                                children: [
                                  Text(
                                    personalizedValue['label'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                  CurrencyText(
                                    personalizedValue['amount'] as double,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                personalizedValue as String? ?? genericOutcome,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required String price,
    required String period,
    String? badge,
    required List<String> features,
    required bool recommended,
    bool isFounder = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        border: recommended
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: recommended ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isFounder
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(feature),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _handlePurchase(context, ref, title),
                  style: FilledButton.styleFrom(
                    backgroundColor: recommended
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    recommended ? loc.startFreeTrial : loc.choosePlanButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) async {
    // Map title to product id
    String productId;
    String planType;
    if (title.contains('Monthly') || title.toLowerCase().contains('monthly')) {
      productId = PurchaseService.monthlySubId;
      planType = 'monthly';
    } else if (title.toLowerCase().contains('annual')) {
      productId = PurchaseService.annualSubId;
      planType = 'annual';
    } else {
      productId = PurchaseService.lifetimeId;
      planType = 'lifetime';
    }

    // Track upgrade button tap
    AnalyticsService().logUpgradeButtonTap(
      location: 'pro_screen',
      planType: planType,
    );

    NavigatorState? rootNavigator = Navigator.of(context, rootNavigator: true);
    var dialogVisible = false;

    void dismissDialog() {
      try {
        if (dialogVisible && rootNavigator.mounted) {
          rootNavigator.pop();
        }
      } catch (_) {
        // ignore
      } finally {
        dialogVisible = false;
      }
    }

    try {
      debugPrint('ProScreen: _handlePurchase called for title=$title');

      // Show loading using the root navigator so it stays above route changes
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogVisible = true;

      final purchaseService = ref.read(purchaseServiceProvider);

      // Timeout product load to avoid the spinner being stuck indefinitely
      final products = await purchaseService
          .loadProducts()
          .timeout(const Duration(seconds: 10));

      debugPrint(
        'ProScreen: Looking for productId=$productId in ${products.map((p) => p.id).toList()}',
      );

      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () {
          // Product not available yet - show helpful message
          final availableIds = products.map((p) => p.id).toList();
          if (productId == PurchaseService.lifetimeId &&
              availableIds.isNotEmpty) {
            throw Exception(
              'Founder Lifetime is being activated by Google Play. Please try again in a few hours, or choose Monthly/Annual now.',
            );
          }
          return throw Exception(
            'Product "$productId" not found. Available: $availableIds',
          );
        },
      );

      // Dismiss loading before launching Play Billing UI
      dismissDialog();

      // Track purchase flow start (Google Play billing sheet opens)
      AnalyticsService().logPurchaseFlowStart(planType);

      final success = await purchaseService.purchaseProduct(product);

      debugPrint(
        'ProScreen: purchaseProduct returned $success for ${product.id}',
      );

      if (!success) {
        // User cancelled - this is normal, track separately
        AnalyticsService().logPurchaseCancelled(planType);

        if (context.mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.purchaseCancelled)),
          );
        }
      } else {
        // Track purchase success (also tracked in PurchaseService)
        // Note: PurchaseService.dart should also call logPurchaseComplete when Pro is granted
      }
    } catch (e, st) {
      debugPrint('ProScreen: purchase flow error: $e\n$st');

      // Track ACTUAL purchase failure (errors, not cancellations)
      AnalyticsService().logPurchaseFailure(
        planType: planType,
        errorMessage: e.toString(),
      );

      // Ensure any dialog is dismissed even if context is no longer mounted
      dismissDialog();

      if (context.mounted) {
        // Show user-friendly error message
        String errorMessage = e.toString();
        if (errorMessage.contains('Founder Lifetime is being activated')) {
          errorMessage =
              'Founder Lifetime is being activated by Google Play.\n\nPlease try again in a few hours, or choose Monthly/Annual now.';
        } else if (e is TimeoutException) {
          errorMessage =
              'Connection to Play Store timed out. Please check your internet connection and try again.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Extra safety to ensure dialog is dismissed
      dismissDialog();
    }
  }

  Widget _buildTrustItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateRealImpact(
    List<Account> accounts,
    List<Liability> liabilities,
    WidgetRef ref,
    BuildContext context,
  ) {
    final loc = AppLocalizations.of(context)!;
    final result = <String, dynamic>{
      'hasData': false,
      'heroText': '',
      'debtSavings': null,
      'concentrationRisk': null,
    };

    // Calculate debt savings potential
    if (liabilities.isNotEmpty) {
      final totalDebt = liabilities.fold<double>(
        0.0,
        (sum, liability) => sum + liability.balance,
      );

      // Estimate potential savings (simplified: ~15% of debt for avalanche optimization)
      final estimatedSavings = totalDebt * 0.15;

      if (estimatedSavings > 1000) {
        result['hasData'] = true;
        result['debtSavings'] = {
          'amount': estimatedSavings,
          'label': loc.saveEst,
        };
      }
    }

    // Calculate concentration risk
    if (accounts.isNotEmpty) {
      final totalAssets = accounts.fold<double>(
        0.0,
        (sum, account) => sum + account.balance,
      );

      // Find largest asset class concentration
      final allocation = {
        'cash': 0.0,
        'bonds': 0.0,
        'usEq': 0.0,
        'intlEq': 0.0,
        'realEstate': 0.0,
        'alt': 0.0,
      };

      for (final account in accounts) {
        final breakdown = account.allocationBreakdown;
        allocation['cash'] =
            allocation['cash']! + (breakdown['cash'] as num).toDouble();
        allocation['bonds'] =
            allocation['bonds']! + (breakdown['bonds'] as num).toDouble();
        allocation['usEq'] =
            allocation['usEq']! + (breakdown['usEq'] as num).toDouble();
        allocation['intlEq'] =
            allocation['intlEq']! + (breakdown['intlEq'] as num).toDouble();
        allocation['realEstate'] = allocation['realEstate']! +
            (breakdown['realEstate'] as num).toDouble();
        allocation['alt'] =
            allocation['alt']! + (breakdown['alt'] as num).toDouble();
      }

      double largestPercentage = 0.0;
      allocation.forEach((key, value) {
        final percentage = totalAssets > 0 ? (value / totalAssets) * 100 : 0.0;
        if (percentage > largestPercentage) {
          largestPercentage = percentage;
        }
      });

      if (largestPercentage > 20) {
        result['hasData'] = true;
        result['concentrationRisk'] = loc.cutConcentration(
          largestPercentage.toStringAsFixed(0),
        );
      }
    }

    // Build hero text
    if (result['hasData'] as bool) {
      final parts = <String>[];
      if (result['debtSavings'] != null) {
        final debt = result['debtSavings'] as Map;
        parts.add('${debt['label']}...'); // Simplified for hero text
      }
      if (result['concentrationRisk'] != null) {
        parts.add(result['concentrationRisk'] as String);
      }
      result['heroText'] = parts.join(' and ');
    }

    return result;
  }
}
