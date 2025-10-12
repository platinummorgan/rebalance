import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/accounts/account_detail_screen.dart';
import 'features/liabilities/liabilities_screen.dart';
import 'features/liabilities/liability_detail_screen.dart';
import 'features/targets/targets_screen.dart';
import 'features/targets/targets_detail_screen.dart';
import 'features/export/export_screen.dart';
import 'features/pro/pro_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/rebalancing/rebalancing_plan_screen.dart';
import 'features/debt/debt_optimizer_screen.dart';
import 'features/scenario/scenario_engine_screen.dart';
import 'features/alerts/custom_alerts_screen.dart';
import 'features/tax/tax_smart_allocation_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String accounts = '/accounts';
  static const String accountDetail = '/accounts/:id';
  static const String addAccount = '/accounts/add';
  static const String liabilities = '/liabilities';
  static const String liabilityDetail = '/liabilities/:id';
  static const String addLiability = '/liabilities/add';
  static const String debtOptimizer = '/debt-optimizer';
  static const String targets = '/targets';
  static const String targetsDetail = '/targets/detail';
  static const String reports = '/reports';
  static const String rebalancing = '/rebalancing';
  static const String scenario = '/scenario';
  static const String customAlerts = '/custom-alerts';
  static const String taxSmart = '/tax-allocation';
  static const String exportData = '/export';
  static const String pro = '/pro';
  static const String about = '/about';

  static final GoRouter router = GoRouter(
    initialLocation: dashboard,
    debugLogDiagnostics: true,
    routes: [
      // Onboarding flow
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // Dashboard/Home
          GoRoute(
            path: dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // Accounts section
          GoRoute(
            path: accounts,
            name: 'accounts',
            builder: (context, state) {
              final assetTypeFilter = state.uri.queryParameters['assetType'];
              return AccountsScreen(assetTypeFilter: assetTypeFilter);
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-account',
                builder: (context, state) => const AccountDetailScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'account-detail',
                builder: (context, state) {
                  final accountId = state.pathParameters['id']!;
                  return AccountDetailScreen(accountId: accountId);
                },
              ),
            ],
          ),

          // Liabilities section
          GoRoute(
            path: liabilities,
            name: 'liabilities',
            builder: (context, state) => const LiabilitiesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-liability',
                builder: (context, state) => const LiabilityDetailScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'liability-detail',
                builder: (context, state) {
                  final liabilityId = state.pathParameters['id']!;
                  return LiabilityDetailScreen(liabilityId: liabilityId);
                },
              ),
            ],
          ),

          // Debt Optimizer Tool
          GoRoute(
            path: debtOptimizer,
            name: 'debt-optimizer',
            builder: (context, state) => const DebtOptimizerScreen(),
          ),

          // Settings & Targets
          GoRoute(
            path: targets,
            name: 'targets',
            builder: (context, state) => const TargetsScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'targets-detail',
                builder: (context, state) => const TargetsDetailScreen(),
              ),
            ],
          ),

          // Reports & Analysis
          GoRoute(
            path: reports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),

          // Rebalancing Plan (Pro Feature)
          GoRoute(
            path: rebalancing,
            name: 'rebalancing',
            builder: (context, state) => const RebalancingPlanScreen(),
          ),

          // Scenario Engine (Pro Feature)
          GoRoute(
            path: scenario,
            name: 'scenario',
            builder: (context, state) => const ScenarioEngineScreen(),
          ),

          // Custom Alerts (Pro Feature)
          GoRoute(
            path: customAlerts,
            name: 'custom-alerts',
            builder: (context, state) => const CustomAlertsScreen(),
          ),

          // Tax-Smart Allocation (Pro Feature)
          GoRoute(
            path: taxSmart,
            name: 'tax-smart-allocation',
            builder: (context, state) => const TaxSmartAllocationScreen(),
          ),

          // Export & Backup
          GoRoute(
            path: exportData,
            name: 'export',
            builder: (context, state) => const ExportScreen(),
          ),

          // Pro features
          GoRoute(
            path: pro,
            name: 'pro',
            builder: (context, state) => const ProScreen(),
          ),

          // About & Legal
          GoRoute(
            path: about,
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Main shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(context),
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Debts',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/accounts')) return 1;
    if (location.startsWith('/liabilities')) return 2;
    if (location.startsWith('/targets') ||
        location.startsWith('/export') ||
        location.startsWith('/pro') ||
        location.startsWith('/about')) {
      return 3;
    }

    return 0; // Dashboard
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.dashboard);
        break;
      case 1:
        context.go(AppRouter.accounts);
        break;
      case 2:
        context.go(AppRouter.liabilities);
        break;
      case 3:
        context.go(AppRouter.targets);
        break;
    }
  }
}

// About screen with developer options
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rebalance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_version.isEmpty ? 'Version loading...' : 'Version $_version'),
            const SizedBox(height: 24),
            const Text(
              'Calculate net worth, visualize asset allocation, and get diversification insights—all private, offline, and fast.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Privacy by Design',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'All your financial data stays on your device. No accounts, no tracking, no cloud storage. Your privacy is guaranteed.',
            ),
            const SizedBox(height: 24),

            // Enhanced Disclaimer Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Important Disclaimer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NOT FINANCIAL ADVICE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rebalance is a financial education and planning tool designed to help you understand and organize your personal finances. It is NOT a substitute for professional financial, investment, tax, or legal advice.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The calculations, scores, and recommendations provided by this app are for informational and educational purposes only. They should not be considered personalized investment advice or a recommendation to buy, sell, or hold any particular security or asset.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Before making any financial decisions, please consult with a qualified financial advisor, accountant, or other professional who understands your individual circumstances, goals, risk tolerance, and tax situation.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Past performance does not guarantee future results. All investments involve risk, including the potential loss of principal.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),

            // Coming Soon Section
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Upcoming features for all users and Pro members:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Free Features Coming Soon
            Text(
              'For Everyone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildComingSoonItem(
              context,
              icon: Icons.widgets_outlined,
              iconColor: Colors.blue.shade600,
              title: 'Home Screen Widget',
              description: 'View your net worth at a glance',
            ),
            const SizedBox(height: 8),
            _buildComingSoonItem(
              context,
              icon: Icons.file_upload_outlined,
              iconColor: Colors.blue.shade600,
              title: 'CSV Import',
              description: 'Import account data from spreadsheets',
            ),
            const SizedBox(height: 8),
            _buildComingSoonItem(
              context,
              icon: Icons.palette_outlined,
              iconColor: Colors.blue.shade600,
              title: 'More Themes',
              description: 'Additional color schemes and customization',
            ),

            const SizedBox(height: 20),

            // Pro Features Coming Soon
            Consumer(
              builder: (context, ref, _) {
                final settingsAsync = ref.watch(settingsProvider);
                final settings = settingsAsync.maybeWhen(
                  data: (s) => s,
                  orElse: () => null,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'For Pro Members',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.workspace_premium,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildComingSoonItem(
                      context,
                      icon: Icons.trending_up,
                      iconColor: Colors.amber.shade600,
                      title: 'Retirement Calculator',
                      description:
                          'Project if you\'re on track for your retirement goals',
                      isPro: true,
                    ),
                    const SizedBox(height: 8),
                    _buildComingSoonItem(
                      context,
                      icon: Icons.show_chart,
                      iconColor: Colors.amber.shade600,
                      title: 'Historical Performance',
                      description:
                          'Track net worth changes over time with charts',
                      isPro: true,
                    ),
                    const SizedBox(height: 8),
                    _buildComingSoonItem(
                      context,
                      icon: Icons.notifications_active,
                      iconColor: Colors.amber.shade600,
                      title: 'Custom Alerts',
                      description:
                          'Get notified when portfolio drifts beyond threshold',
                      isPro: true,
                    ),
                    const SizedBox(height: 8),
                    _buildComingSoonItem(
                      context,
                      icon: Icons.auto_awesome,
                      iconColor: Colors.amber.shade600,
                      title: 'Auto-Rebalancing',
                      description:
                          'Specific buy/sell recommendations to rebalance',
                      isPro: true,
                    ),
                    const SizedBox(height: 8),
                    _buildComingSoonItem(
                      context,
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.amber.shade600,
                      title: 'Individual Debt Optimizer',
                      description:
                          'Focus on accelerating payoff for specific debts',
                      isPro: true,
                    ),
                    const SizedBox(height: 8),
                    _buildComingSoonItem(
                      context,
                      icon: Icons.download,
                      iconColor: Colors.amber.shade600,
                      title: 'Export Payoff Schedule',
                      description:
                          'Download detailed month-by-month schedule as CSV',
                      isPro: true,
                    ),
                    const SizedBox(height: 16),
                    if (settings != null && !settings.isPro)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Want early access to Pro features? Upgrade now to support development.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to send feedback via Google Form
Future<void> _sendFeedback(BuildContext context) async {
  const String feedbackFormUrl = 'https://forms.gle/68XLBtDxWnmSKhhj8';

  final Uri formUri = Uri.parse(feedbackFormUrl);

  try {
    if (await canLaunchUrl(formUri)) {
      await launchUrl(
        formUri,
        mode: LaunchMode.externalApplication, // Opens in browser
      );
    } else {
      throw 'Could not launch form';
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not open feedback form. Please try again later.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

// Helper function to report a bug via Google Form
Future<void> _reportBug(BuildContext context) async {
  const String bugReportFormUrl = 'https://forms.gle/CRXdzsBrRoMrQmsU9';

  final Uri formUri = Uri.parse(bugReportFormUrl);

  try {
    if (await canLaunchUrl(formUri)) {
      await launchUrl(
        formUri,
        mode: LaunchMode.externalApplication, // Opens in browser
      );
    } else {
      throw 'Could not launch form';
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not open bug report form. Please try again later.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

// Helper widget to build coming soon items
Widget _buildComingSoonItem(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String description,
  bool isPro = false,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
