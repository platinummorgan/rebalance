import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../routes.dart' show AppRouter;
import 'package:intl/intl.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding state
  RiskBand _selectedRiskBand = RiskBand.balanced;
  double _monthlyEssentials = 5000.0;
  final TextEditingController _essentialsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _essentialsController.text =
        NumberFormat.simpleCurrency().format(_monthlyEssentials);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _essentialsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildRiskBandPage(),
                  _buildEssentialsPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed:
                        _currentPage < 2 ? _nextPage : _completeOnboarding,
                    child: Text(_currentPage < 2 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to\nRebalance',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Calculate your net worth, visualize asset allocation, and get personalized diversification insights.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy First',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• No sign-up required\n'
                    '• All data stored locally\n'
                    '• No ads or tracking\n'
                    '• Encrypted storage',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBandPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'What\'s your investment approach?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'This helps us suggest appropriate asset allocation targets.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildRiskBandCard(
                  RiskBand.conservative,
                  'Conservative',
                  '40% Stocks / 60% Bonds',
                  'Lower risk, steady growth. Good for those near retirement or with low risk tolerance.',
                  Icons.security,
                ),
                const SizedBox(height: 16),
                _buildRiskBandCard(
                  RiskBand.balanced,
                  'Balanced',
                  '60% Stocks / 40% Bonds',
                  'Moderate risk and growth. Balanced approach for most long-term investors.',
                  Icons.balance,
                ),
                const SizedBox(height: 16),
                _buildRiskBandCard(
                  RiskBand.growth,
                  'Growth',
                  '80% Stocks / 20% Bonds',
                  'Higher risk, higher potential returns. Good for younger investors with long time horizons.',
                  Icons.trending_up,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBandCard(
    RiskBand riskBand,
    String title,
    String allocation,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedRiskBand == riskBand;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRiskBand = riskBand;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                allocation,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEssentialsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'What are your monthly essentials?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'This helps calculate your emergency fund needs and liquidity requirements.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _essentialsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monthly Essentials',
              prefixIcon: Icon(Icons.attach_money),
              helperText:
                  'Include rent, utilities, food, insurance, minimum debt payments',
              helperMaxLines: 2,
            ),
            onChanged: (value) {
              // Parse currency input
              final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
              final parsed = double.tryParse(cleaned);
              if (parsed != null) {
                _monthlyEssentials = parsed;
              }
            },
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What to Include',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Housing (rent/mortgage, utilities)\n'
                    '• Food and groceries\n'
                    '• Transportation\n'
                    '• Insurance premiums\n'
                    '• Minimum debt payments\n'
                    '• Essential subscriptions',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Don\'t include: Dining out, entertainment, travel, or other discretionary spending.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      // Create settings with onboarding data
      final settings = Settings(
        riskBand: _selectedRiskBand,
        monthlyEssentials: _monthlyEssentials,
      );

      // Save settings
      await ref.read(settingsProvider.notifier).updateSettings(settings);

      // Navigate to dashboard
      if (mounted) {
        context.go(AppRouter.dashboard);
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
