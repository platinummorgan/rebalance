import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../services/purchase_service.dart';
import '../../data/models.dart';
import '../../routes.dart' show AppRouter;

/// Outcome-focused Pro screen showing real financial impact
class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Features'),
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
              'Your Pro Features',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Feature cards with outcomes
            _buildActiveFeatureCard(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Debt Payoff Optimizer',
              description: 'Find the fastest path to debt freedom',
              stat: 'Save thousands in interest',
              color: Colors.blue,
              onTap: () => context.push(AppRouter.debtOptimizer),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.trending_up,
              title: 'Rebalancing Autopilot',
              description: 'Get specific trade instructions',
              stat: 'Reduce portfolio risk',
              color: Colors.purple,
              onTap: () => context.push(AppRouter.rebalancing),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.psychology,
              title: 'What-If Scenario Engine',
              description: 'Model retirement outcomes',
              stat: 'See probability of success',
              color: Colors.orange,
              onTap: () => context.push(AppRouter.scenario),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.notifications_active,
              title: 'Custom Alerts',
              description: 'Get alerts with dollar context',
              stat: 'Know the financial impact',
              color: Colors.red,
              onTap: () => context.push(AppRouter.customAlerts),
            ),

            _buildActiveFeatureCard(
              context,
              icon: Icons.calculate,
              title: 'Tax-Smart Allocation',
              description: 'Optimize asset location',
              stat: 'Save on taxes annually',
              color: Colors.teal,
              onTap: () => context.push(AppRouter.taxSmart),
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
                    'Plan Details',
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
                        'Pro Active',
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
    // Calculate personalized savings
    final personalizedStats = _calculatePersonalizedSavings(
      accounts,
      liabilities,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Pro'),
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
                      const Expanded(
                        child: Text(
                          'Rebalance Pro',
                          style: TextStyle(
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
                          const Text(
                            'Based on your portfolio:',
                            style: TextStyle(
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
                    const Text(
                      'Save money and reduce risk with intelligent financial planning',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
                    title: 'Debt Payoff Optimizer',
                    personalizedValue:
                        personalizedStats['debtSavings'] as String?,
                    genericOutcome: 'Save thousands in interest',
                    description:
                        'Compare avalanche vs snowball strategies. Get month-by-month payment schedule and see total interest saved.',
                    color: Colors.blue,
                    onTap: () => context.push(AppRouter.debtOptimizer),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.trending_up,
                    title: 'Rebalancing Autopilot',
                    personalizedValue:
                        personalizedStats['concentrationRisk'] as String?,
                    genericOutcome: 'Cut concentration risk',
                    description:
                        'Get specific trade instructions like "Move \$2,150 this month". See before/after risk metrics and volatility reduction.',
                    color: Colors.purple,
                    onTap: () => context.push(AppRouter.rebalancing),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.psychology,
                    title: 'What-If Scenario Engine',
                    personalizedValue: null,
                    genericOutcome: 'See probability of hitting goals',
                    description:
                        'Monte Carlo simulation (1,000 runs) shows success probability. Adjust contributions, returns, and timeline to optimize your plan.',
                    color: Colors.orange,
                    onTap: () => context.push(AppRouter.scenario),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.notifications_active,
                    title: 'Custom Alerts with Context',
                    personalizedValue: null,
                    genericOutcome: 'Know the financial impact',
                    description:
                        'Set custom thresholds for concentration, drift, DSCR. Each alert shows dollar impact: "Breach adds \$4,200 excess risk".',
                    color: Colors.red,
                    onTap: () => context.push(AppRouter.customAlerts),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.calculate,
                    title: 'Tax-Smart Allocation',
                    personalizedValue: null,
                    genericOutcome: 'Est. \$480/year saved',
                    description:
                        'Optimize which accounts hold which assets. Identify tax-loss harvesting opportunities. Minimize annual tax drag.',
                    color: Colors.teal,
                    onTap: () => context.push(AppRouter.taxSmart),
                  ),

                  _buildOutcomeFeatureCard(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Advanced Portfolio Analytics',
                    personalizedValue: null,
                    genericOutcome: 'Professional-grade analysis',
                    description:
                        'HHI concentration index, factor exposure breakdown, multi-portfolio tracking, custom scoring weights.',
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 24),

                  // Pricing cards
                  Text(
                    'Choose Your Plan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  _buildPricingCard(
                    context,
                    ref: ref,
                    title: 'Pro Monthly',
                    price: '\$3.99',
                    period: 'per month',
                    features: [
                      'All Pro features',
                      'Cancel anytime',
                      '7-day free trial',
                    ],
                    recommended: false,
                  ),

                  const SizedBox(height: 12),

                  _buildPricingCard(
                    context,
                    ref: ref,
                    title: 'Annual',
                    price: '\$23.99',
                    period: 'per year',
                    badge: 'BEST VALUE',
                    features: [
                      'All Pro features',
                      'Save \$24',
                      '7-day free trial',
                    ],
                    recommended: true,
                  ),

                  const SizedBox(height: 12),

                  _buildPricingCard(
                    context,
                    ref: ref,
                    title: 'Founder Lifetime',
                    price: '\$39.99',
                    period: 'one time',
                    badge: 'LIMITED',
                    features: [
                      'Everything forever',
                      'First 1,000 founders',
                      'Price increases after',
                    ],
                    recommended: false,
                    isFounder: true,
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
                          '100% Privacy',
                          'All data stays on your device',
                        ),
                        const SizedBox(height: 12),
                        _buildTrustItem(
                          context,
                          Icons.lock,
                          'Encrypted Storage',
                          'Bank-grade security',
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
    required String? personalizedValue,
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
                        Text(
                          personalizedValue ?? genericOutcome,
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
                    recommended ? 'Start Free Trial' : 'Choose Plan',
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
    if (title.contains('Monthly') || title.toLowerCase().contains('monthly')) {
      productId = PurchaseService.monthlySubId;
    } else if (title.toLowerCase().contains('annual')) {
      productId = PurchaseService.annualSubId;
    } else {
      productId = PurchaseService.lifetimeId;
    }

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
          'ProScreen: Looking for productId=$productId in ${products.map((p) => p.id).toList()}');

      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () {
          // Product not available yet - show helpful message
          final availableIds = products.map((p) => p.id).toList();
          if (productId == PurchaseService.lifetimeId &&
              availableIds.isNotEmpty) {
            throw Exception(
                'Founder Lifetime is being activated by Google Play. Please try again in a few hours, or choose Monthly/Annual now.');
          }
          return throw Exception(
              'Product "$productId" not found. Available: $availableIds');
        },
      );

      // Dismiss loading before launching Play Billing UI
      dismissDialog();

      final success = await purchaseService.purchaseProduct(product);

      debugPrint(
        'ProScreen: purchaseProduct returned $success for ${product.id}',
      );

      if (!success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase cancelled or failed')),
          );
        }
      }
    } catch (e, st) {
      debugPrint('ProScreen: purchase flow error: $e\n$st');
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

  Map<String, dynamic> _calculatePersonalizedSavings(
    List<Account> accounts,
    List<Liability> liabilities,
  ) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
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
        result['debtSavings'] =
            'Save est. ${formatter.format(estimatedSavings)}';
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
        result['concentrationRisk'] =
            'Cut concentration from ${largestPercentage.toStringAsFixed(0)}% → 20%';
      }
    }

    // Build hero text
    if (result['hasData'] as bool) {
      final parts = <String>[];
      if (result['debtSavings'] != null) {
        parts.add(result['debtSavings'] as String);
      }
      if (result['concentrationRisk'] != null) {
        parts.add(result['concentrationRisk'] as String);
      }
      result['heroText'] = parts.join(' and ');
    }

    return result;
  }
}
