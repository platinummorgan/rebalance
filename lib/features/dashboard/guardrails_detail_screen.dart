import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../generated/app_localizations.dart';
import '../../data/models.dart';
import '../../routes.dart' show AppRouter;
import '../../widgets/currency_text.dart';
import '../../utils/currency_formatter.dart';
import '../../services/analytics_service.dart';
import '../../app.dart';

class GuardrailsDetailScreen extends ConsumerStatefulWidget {
  const GuardrailsDetailScreen({super.key});

  @override
  ConsumerState<GuardrailsDetailScreen> createState() =>
      _GuardrailsDetailScreenState();
}

class _GuardrailsDetailScreenState
    extends ConsumerState<GuardrailsDetailScreen> {
  double _additionalSpending = 0;
  final _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logGuardrailsScreenView();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final settingsAsync = ref.watch(settingsProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final liabilitiesAsync = ref.watch(liabilitiesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.weeklyGuardrails),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) => incomesAsync.when(
          data: (incomes) => liabilitiesAsync.when(
            data: (liabilities) => accountsAsync.when(
              data: (accounts) => expensesAsync.when(
                data: (expenses) {
                  final weeklyData = _calculateWeeklyData(
                    settings,
                    incomes,
                    liabilities,
                    accounts,
                    expenses,
                  );

                  return _buildContent(
                    context,
                    loc,
                    theme,
                    weeklyData,
                    settings,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    Map<String, dynamic> weeklyData,
    Settings settings,
  ) {
    final safeToSpend = (weeklyData['safeToSpend'] as num).toDouble();
    final weeklyIncome = (weeklyData['weeklyIncome'] as num).toDouble();
    final weeklyBills = (weeklyData['weeklyBills'] as num).toDouble();
    final weeklyEssentials = (weeklyData['weeklyEssentials'] as num).toDouble();
    final weeklyDebtPayments =
        (weeklyData['weeklyDebtPayments'] as num).toDouble();
    final daysOfBuffer = weeklyData['daysOfBuffer'] as int;
    final dailyBurn = (weeklyData['dailyBurn'] as num).toDouble();

    // Calculate what-if scenario
    final adjustedSafeToSpend = safeToSpend - _additionalSpending;
    final bufferWithAdditional =
        dailyBurn > 0 ? (adjustedSafeToSpend / dailyBurn) : 0.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Safe to spend card
            _buildSafeToSpendCard(
              context,
              loc,
              theme,
              safeToSpend,
              daysOfBuffer,
              settings,
            ),

            const SizedBox(height: 24),

            // What-if slider section
            _buildWhatIfSection(
              context,
              loc,
              theme,
              safeToSpend,
              adjustedSafeToSpend,
              bufferWithAdditional,
              settings,
            ),

            const SizedBox(height: 24),

            // Breakdown section
            _buildBreakdownSection(
              context,
              loc,
              theme,
              weeklyIncome,
              weeklyBills,
              weeklyEssentials,
              weeklyDebtPayments,
              safeToSpend,
              settings,
            ),

            const SizedBox(height: 24),

            // Pro upsell card (conditional)
            _buildProUpsellCard(context, loc, theme, safeToSpend, daysOfBuffer),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeToSpendCard(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    double safeToSpend,
    int daysOfBuffer,
    Settings settings,
  ) {
    // Calculate buffer day
    final today = DateTime.now();
    final bufferDay = today.add(Duration(days: daysOfBuffer));
    final dayName = DateFormat.EEEE().format(bufferDay);

    final isNegative = safeToSpend < 0;
    final isOnTrack = !isNegative && daysOfBuffer >= 3;

    // Determine state and accessibility icon
    String stateIcon;
    List<Color> gradientColors;
    if (isNegative) {
      stateIcon = '🚨'; // Red alert
      gradientColors = [Colors.red.shade600, Colors.red.shade700];
    } else if (isOnTrack) {
      stateIcon = '✓'; // Green checkmark
      gradientColors = [Colors.green.shade600, Colors.green.shade700];
    } else {
      stateIcon = '⚠'; // Orange warning
      gradientColors = [Colors.orange.shade600, Colors.orange.shade700];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isNegative ? loc.overBudgetThisWeek : loc.safeToSpendThisWeek,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Accessibility icon
              Text(
                stateIcon,
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CurrencyText(
            safeToSpend,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          if (isNegative)
            Text(
              'You\'ll be short ${CurrencyFormatter.format(safeToSpend.abs(), settings.currency)} by $dayName',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            )
          else
            Text(
              loc.bufferUntilDay(dayName),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWhatIfSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    double safeToSpend,
    double adjustedSafeToSpend,
    double bufferWithAdditional,
    Settings settings,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    // Calculate shortage scenario
    final shortage = _additionalSpending > safeToSpend
        ? _additionalSpending - safeToSpend
        : 0.0;

    final shortageDate = DateTime.now().add(
      Duration(days: bufferWithAdditional.floor()),
    );
    final shortageDateStr = DateFormat.EEEE().format(shortageDate);

    // Determine tier based on remaining buffer (more dramatic thresholds)
    final isGreen =
        adjustedSafeToSpend > (safeToSpend * 0.25); // >25% buffer remaining
    final isYellow = adjustedSafeToSpend > 0 &&
        adjustedSafeToSpend <= (safeToSpend * 0.25); // <25% but still positive
    final isRed = adjustedSafeToSpend <= 0; // Over the line

    // Dynamic slider color and BACKGROUND colors
    Color sliderActiveColor;
    Color cardBackgroundColor;
    Color messageTextColor;
    IconData messageIcon;

    if (isGreen) {
      sliderActiveColor = Colors.green;
      cardBackgroundColor = isDark
          ? const Color(0xFF065f46)
          : const Color(0xFFd1fae5); // green-800 : green-100
      messageTextColor = isDark ? Colors.green[100]! : Colors.green[900]!;
      messageIcon = Icons.check_circle;
    } else if (isYellow) {
      sliderActiveColor = Colors.yellow.shade700;
      cardBackgroundColor = isDark
          ? const Color(0xFF854d0e)
          : const Color(0xFFfef3c7); // yellow-800 : yellow-100
      messageTextColor = isDark ? Colors.yellow[100]! : Colors.yellow[900]!;
      messageIcon = Icons.warning_amber;
    } else {
      sliderActiveColor = Colors.red;
      cardBackgroundColor = isDark
          ? const Color(0xFF991b1b)
          : const Color(0xFFfee2e2); // red-800 : red-100
      messageTextColor = isDark ? Colors.red[100]! : Colors.red[900]!;
      messageIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.whatIfYouSpendMore,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // Slider
          Row(
            children: [
              Text(
                loc.additionalSpending,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const Spacer(),
              CurrencyText(
                _additionalSpending,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: sliderActiveColor,
              thumbColor: sliderActiveColor,
              overlayColor: sliderActiveColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _additionalSpending,
              min: 0,
              max: (safeToSpend * 2).clamp(100, 1000),
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _additionalSpending = value;
                });
                // Track slider change
                _analytics.logGuardrailsSliderChange(
                  additionalSpending: value,
                  safeToSpend: safeToSpend,
                );
                // Track state changes
                final adjustedAmount = safeToSpend - value;
                if (adjustedAmount <= 0 && value > 0) {
                  // RED state
                  final dailyBurn = bufferWithAdditional > 0
                      ? (adjustedAmount / bufferWithAdditional)
                      : 0.0;
                  final shortageDate = DateTime.now().add(
                    Duration(days: (adjustedAmount / dailyBurn).floor()),
                  );
                  _analytics.logGuardrailsStateRed(
                    shortage: (value - safeToSpend).abs(),
                    dayName: DateFormat.EEEE().format(shortageDate),
                  );
                } else if (adjustedAmount > 0 &&
                    adjustedAmount <= (safeToSpend * 0.25) &&
                    value > 0) {
                  // YELLOW state (<25% buffer left)
                  _analytics.logGuardrailsStateYellow(
                    bufferLeft: adjustedAmount,
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          // New safe-to-spend display (if slider moved)
          if (_additionalSpending > 0) ...[
            Text(
              'New safe-to-spend: ${CurrencyFormatter.format(adjustedSafeToSpend, settings.currency)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // "After this extra..." helper text
          if (_additionalSpending > 0) ...[
            Text(
              'After this extra ${CurrencyFormatter.format(_additionalSpending, settings.currency)}, you\'ll have ${CurrencyFormatter.format(adjustedSafeToSpend.clamp(0, double.infinity), settings.currency)} left this week.',
              style: TextStyle(
                fontSize: 13,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Result message with DRAMATIC background color
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  messageIcon,
                  color: sliderActiveColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMessageContent(
                    isGreen,
                    isYellow,
                    isRed,
                    adjustedSafeToSpend,
                    shortage,
                    shortageDateStr,
                    messageTextColor,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    bool isGreen,
    bool isYellow,
    bool isRed,
    double adjustedSafeToSpend,
    double shortage,
    String shortageDateStr,
    Color textColor,
    bool isDark,
  ) {
    if (isGreen) {
      // >25% buffer remaining - comfortable
      return Row(
        children: [
          Text(
            'Still on track with ',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
          CurrencyText(
            adjustedSafeToSpend,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            ' buffer',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      );
    } else if (isYellow) {
      // <25% buffer but still positive - TIGHT
      return Row(
        children: [
          Text(
            'Tight week – only ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          CurrencyText(
            adjustedSafeToSpend,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            ' buffer left',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    } else {
      // Over the line - RED WARNING
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '⚠ You\'d be short ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              CurrencyText(
                shortage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                ' this week',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'You\'d go negative by $shortageDateStr',
            style: TextStyle(
              fontSize: 13,
              color: textColor,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBreakdownSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    double weeklyIncome,
    double weeklyBills,
    double weeklyEssentials,
    double weeklyDebtPayments,
    double buffer,
    Settings settings,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildBreakdownRow(
            context,
            loc,
            theme,
            loc.weeklyIncome,
            weeklyIncome,
            Icons.arrow_downward,
            Colors.green,
            settings,
            null,
          ),
          const Divider(height: 24),
          _buildBreakdownRow(
            context,
            loc,
            theme,
            loc.weeklyBills,
            weeklyBills,
            Icons.arrow_upward,
            Colors.red,
            settings,
            null,
          ),
          // Show detailed breakdown of weekly bills
          if (weeklyEssentials > 0 || weeklyDebtPayments > 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Column(
                children: [
                  if (weeklyEssentials > 0)
                    _buildBreakdownRow(
                      context,
                      loc,
                      theme,
                      'Monthly Essentials',
                      weeklyEssentials,
                      Icons.home_outlined,
                      Colors.orange,
                      settings,
                      AppRouter.targetsDetail,
                      isSubItem: true,
                    ),
                  if (weeklyEssentials > 0 && weeklyDebtPayments > 0)
                    const SizedBox(height: 8),
                  if (weeklyDebtPayments > 0)
                    _buildBreakdownRow(
                      context,
                      loc,
                      theme,
                      'Debt Payments',
                      weeklyDebtPayments,
                      Icons.credit_card,
                      Colors.deepOrange,
                      settings,
                      AppRouter.liabilities,
                      isSubItem: true,
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 24),
          _buildBreakdownRow(
            context,
            loc,
            theme,
            loc.bufferDiscretionary,
            buffer,
            Icons.savings,
            Colors.blue,
            settings,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    String label,
    double amount,
    IconData icon,
    Color color,
    Settings settings,
    String? editRoute, {
    bool isSubItem = false,
  }) {
    // Determine which screen to navigate to based on label if not explicitly provided
    if (editRoute == null) {
      if (label == loc.weeklyIncome) {
        editRoute = AppRouter.income;
      }
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: isSubItem ? 16 : 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSubItem ? 13 : 15,
                  color: theme.textTheme.bodyLarge?.color
                      ?.withValues(alpha: isSubItem ? 0.8 : 1.0),
                ),
              ),
              if (editRoute != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    context.push(editRoute!);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.edit,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        CurrencyText(
          amount,
          style: TextStyle(
            fontSize: isSubItem ? 14 : 16,
            fontWeight: isSubItem ? FontWeight.w600 : FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildProUpsellCard(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    double safeToSpend,
    int daysOfBuffer,
  ) {
    // Debug: Print buffer value to understand why card isn't showing
    debugPrint(
      '[ProCard] daysOfBuffer=$daysOfBuffer, safeToSpend=$safeToSpend, shouldShow=${daysOfBuffer < 3 || safeToSpend < 0}',
    );

    // Show Pro card when user is in trouble:
    // 1. Low buffer (< 3 days of cash), OR
    // 2. Negative safe-to-spend (income < bills)
    final shouldShow = daysOfBuffer < 3 || safeToSpend < 0;

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    // Track Pro banner view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analytics.logGuardrailsProBannerView();
    });

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF7c3aed), // violet-600
                  const Color(0xFF6366f1), // indigo-500
                ]
              : [
                  const Color(0xFF8b5cf6), // violet-500
                  const Color(0xFF6366f1), // indigo-500
                ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Never have a "broke week" again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rebalance Pro warns you before you go over your safe-to-spend for the week, so you\'re not blindsided on Friday.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _analytics.logProBannerClick();
                context.push(AppRouter.pro);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7c3aed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade to Pro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateWeeklyData(
    Settings settings,
    List<Income> incomes,
    List<Liability> liabilities,
    List<Account> accounts,
    List<MonthlyExpense> expenses,
  ) {
    // Calculate weekly income (using monthlyNet - after tax)
    double weeklyIncome = 0;
    for (var income in incomes) {
      final netMonthly = income.monthlyNet;
      weeklyIncome += netMonthly / 4.33;
    }

    // Calculate weekly bills (monthly expenses + debt payments)
    double monthlyExpensesTotal = 0;
    for (var expense in expenses) {
      monthlyExpensesTotal += expense.amount;
    }
    final weeklyEssentials = monthlyExpensesTotal / 4.33;
    double weeklyDebtPayments = 0;

    for (var liability in liabilities) {
      final monthlyPayment = liability.minPayment;
      weeklyDebtPayments += monthlyPayment / 4.33;
    }

    final weeklyBills = weeklyEssentials + weeklyDebtPayments;

    // Calculate total cash across accounts
    double totalCash = 0;
    for (var account in accounts) {
      if (account.kind == 'cash' || account.kind == 'checking') {
        totalCash += account.balance;
      }
    }

    // Calculate daily burn rate and buffer days
    final dailyBurn = weeklyBills / 7;

    // Buffer is always: how many days can cash cover the bills?
    final daysWeCanCover = dailyBurn > 0 ? (totalCash / dailyBurn) : 0;
    final cappedDays = daysWeCanCover.floor().clamp(0, 7);

    // Safe to spend = weekly income - weekly bills (can be negative)
    final safeToSpend = weeklyIncome - weeklyBills;

    return {
      'safeToSpend': safeToSpend,
      'weeklyIncome': weeklyIncome,
      'weeklyBills': weeklyBills,
      'weeklyEssentials': weeklyEssentials,
      'weeklyDebtPayments': weeklyDebtPayments,
      'daysOfBuffer': cappedDays,
      'dailyBurn': dailyBurn,
      'isOnTrack': cappedDays >= 3,
    };
  }
}
