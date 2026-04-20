import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingStepsSheet extends StatelessWidget {
  final ScrollController scrollController;

  const OnboardingStepsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Add Your Accounts',
        'description':
            'Start by adding your checking, savings, and investment accounts to track your total assets.',
        'action': 'Add Account',
        'route': '/accounts',
      },
      {
        'icon': Icons.credit_card_outlined,
        'title': 'Track Your Liabilities',
        'description':
            'Add mortgages, loans, and credit cards to get your complete net worth picture.',
        'action': 'Add Liability',
        'route': '/liabilities',
      },
      {
        'icon': Icons.gps_fixed,
        'title': 'Set Your Goals',
        'description':
            'Define your risk tolerance and financial goals to get personalized recommendations.',
        'action': 'Set Targets',
        'route': '/targets',
      },
      {
        'icon': Icons.donut_large_outlined,
        'title': 'Monitor Allocation',
        'description':
            'Review your asset allocation and get insights on rebalancing opportunities.',
        'action': 'View Reports',
        'route': '/reports',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Text(
            'Getting Started',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow these steps to set up your financial dashboard',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Steps list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  elevation: 1,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.push(step['route'] as String);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      step['title'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  step['description'] as String,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      step['action'] as String,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
