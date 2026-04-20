import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../data/models.dart';
import '../../utils/currency_formatter.dart';
import '../../services/exchange_rate_service.dart';
import '../../generated/app_localizations.dart';

class TargetsDetailScreen extends ConsumerStatefulWidget {
  const TargetsDetailScreen({super.key});

  @override
  ConsumerState<TargetsDetailScreen> createState() =>
      _TargetsDetailScreenState();
}

class _TargetsDetailScreenState extends ConsumerState<TargetsDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _usEquityController = TextEditingController();
  // final _driftThresholdController = TextEditingController(); // Commented out with drift alerts
  final _monthlyEssentialsController = TextEditingController();

  // Focus nodes
  final _usEquityFocus = FocusNode();
  // final _driftThresholdFocus = FocusNode(); // Commented out with drift alerts
  final _monthlyEssentialsFocus = FocusNode();

  RiskBand _selectedRiskBand = RiskBand.balanced;
  // bool _notificationsEnabled = true; // Commented out with drift alerts
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current settings
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ref.read(settingsProvider).value;
      if (settings != null) {
        // Convert monthly essentials from USD to display currency
        final exchangeService = ExchangeRateService();
        final convertedMonthlyEssentials = await exchangeService.convert(
          settings.monthlyEssentials,
          'USD',
          settings.currency,
        );

        _usEquityController.text = settings.usEquityTargetPct.toString();
        // _driftThresholdController.text = settings.driftThresholdPct.toString(); // Commented out with drift alerts
        _monthlyEssentialsController.text =
            convertedMonthlyEssentials.toStringAsFixed(2);
        _selectedRiskBand = settings.riskBand;
        // _notificationsEnabled = settings.notificationsEnabled; // Commented out with drift alerts
      }
    });

    // Add listeners to detect changes
    _usEquityController.addListener(_onFieldChanged);
    // _driftThresholdController.addListener(_onFieldChanged); // Commented out with drift alerts
    _monthlyEssentialsController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _usEquityController.dispose();
    // _driftThresholdController.dispose(); // Commented out with drift alerts
    _monthlyEssentialsController.dispose();
    _usEquityFocus.dispose();
    // _driftThresholdFocus.dispose(); // Commented out with drift alerts
    _monthlyEssentialsFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.targetsAndAlerts),
          actions: [
            if (_hasChanges) ...[
              TextButton(
                onPressed: _saveSettings,
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
              tooltip: AppLocalizations.of(context)!.help,
            ),
          ],
        ),
        body: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!
                      .errorLoadingSettings(error.toString()),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(settingsProvider.notifier).reload(),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
          data: (settings) => _buildForm(context, settings),
        ),
        floatingActionButton: _hasChanges
            ? FloatingActionButton.extended(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.saveChanges),
              )
            : null,
      ),
    );
  }

  Widget _buildForm(BuildContext context, Settings settings) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Risk Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.riskProfile,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.riskProfileDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRiskBandSelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Allocation Targets Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.donut_large,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.allocationTargets,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.allocationTargetsDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // US Equity Target
                  TextFormField(
                    controller: _usEquityController,
                    focusNode: _usEquityFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}'),
                      ),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.usEquityTarget,
                      hintText: '60.0',
                      suffixText: '%',
                      helperText:
                          AppLocalizations.of(context)!.usEquityTargetHelper,
                    ),
                    validator: (value) {
                      final loc = AppLocalizations.of(context)!;
                      if (value == null || value.isEmpty) {
                        return loc.enterTargetPercentage;
                      }
                      final percentage = double.tryParse(value);
                      if (percentage == null) {
                        return loc.enterValidNumber;
                      }
                      if (percentage < 0 || percentage > 100) {
                        return loc.percentageMustBeBetween;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) =>
                        _monthlyEssentialsFocus.requestFocus(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TODO: Reactivate when automatic account syncing is implemented
          // Drift & Alerts Section - Currently commented out for manual entry workflow
          // Users see allocation changes immediately on dashboard when updating accounts manually
          /*
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notification_important,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Drift & Alerts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Get notified when your allocation drifts from targets.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Drift Threshold
                  TextFormField(
                    controller: _driftThresholdController,
                    focusNode: _driftThresholdFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Drift Threshold %',
                      hintText: '5.0',
                      suffixText: '%',
                      helperText: 'Notify when allocation drifts beyond this threshold',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a drift threshold';
                      }
                      final percentage = double.tryParse(value);
                      if (percentage == null) {
                        return 'Please enter a valid number';
                      }
                      if (percentage < 1 || percentage > 20) {
                        return 'Threshold should be between 1% and 20%';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _monthlyEssentialsFocus.requestFocus(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Notifications Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Get alerts about drift and rebalancing opportunities'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        _hasChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          */

          const SizedBox(height: 16),

          // Budget & Planning Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.budgetAndPlanning,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.budgetAndPlanningDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monthly Essentials
                  Builder(
                    builder: (context) {
                      final loc = AppLocalizations.of(context)!;
                      final currencySymbol =
                          CurrencyFormatter.format(0, settings.currency)
                              .replaceAll('0', '')
                              .replaceAll('.', '')
                              .replaceAll(',', '')
                              .trim();

                      // Calculate weekly amount for display
                      final currentMonthly =
                          double.tryParse(_monthlyEssentialsController.text) ??
                              0;
                      final weeklyAmount = currentMonthly / 4.33;
                      final weeklyFormatted = CurrencyFormatter.format(
                        weeklyAmount,
                        settings.currency,
                      );

                      final helperText = currentMonthly > 0
                          ? 'Rent, utilities, groceries, insurance, etc. ($weeklyFormatted/week for Weekly Guardrails)'
                          : (settings.currency != 'USD'
                              ? loc.monthlyEssentialsHelperUSD
                              : loc.monthlyEssentialsHelper);

                      return TextFormField(
                        controller: _monthlyEssentialsController,
                        focusNode: _monthlyEssentialsFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(7),
                        ],
                        decoration: InputDecoration(
                          labelText: loc.monthlyEssentialExpenses,
                          hintText: '5000',
                          prefixText: '$currencySymbol ',
                          helperText: helperText,
                          helperMaxLines: 3,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.enterMonthlyEssentials;
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return loc.enterValidAmount;
                          }
                          if (amount < 0) {
                            return loc.amountCannotBeNegative;
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            // Trigger rebuild to update helper text
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildRiskBandSelector() {
    return Column(
      children: RiskBand.values.map((band) {
        final isSelected = _selectedRiskBand == band;
        final (title, subtitle, allocation) = _getRiskBandInfo(band);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedRiskBand = band;
                  _hasChanges = true;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            allocation,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  (String, String, String) _getRiskBandInfo(RiskBand band) {
    final loc = AppLocalizations.of(context)!;
    switch (band) {
      case RiskBand.conservative:
        return (
          loc.riskConservative,
          loc.riskConservativeDescription,
          loc.riskConservativeAllocation
        );
      case RiskBand.balanced:
        return (
          loc.riskBalanced,
          loc.riskBalancedDescription,
          loc.riskBalancedAllocation
        );
      case RiskBand.growth:
        return (
          loc.riskGrowth,
          loc.riskGrowthDescription,
          loc.riskGrowthAllocation
        );
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final currentSettings = ref.read(settingsProvider).value;
      if (currentSettings == null) return;

      // Convert monthly essentials from display currency to USD
      final exchangeService = ExchangeRateService();
      final monthlyEssentialsInDisplayCurrency =
          double.parse(_monthlyEssentialsController.text);
      final monthlyEssentialsInUSD = await exchangeService.convert(
        monthlyEssentialsInDisplayCurrency,
        currentSettings.currency,
        'USD',
      );

      final updatedSettings = Settings(
        riskBand: _selectedRiskBand,
        monthlyEssentials: monthlyEssentialsInUSD,
        driftThresholdPct:
            currentSettings.driftThresholdPct, // Keep existing value
        notificationsEnabled:
            currentSettings.notificationsEnabled, // Keep existing value
        usEquityTargetPct: double.parse(_usEquityController.text),
        isPro: currentSettings.isPro,
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
        concentrationRiskResolvedAt:
            currentSettings.concentrationRiskResolvedAt,
        homeCountry: currentSettings.homeCountry,
        globalDiversificationMode: currentSettings.globalDiversificationMode,
        intlTargetOverride: currentSettings.intlTargetOverride,
        intlTolerancePct: currentSettings.intlTolerancePct,
        intlFloorPct: currentSettings.intlFloorPct,
        intlPenaltyScale: currentSettings.intlPenaltyScale,
        financialHealthBaseline: currentSettings.financialHealthBaseline,
        financialHealthGlobalScale: currentSettings.financialHealthGlobalScale,
        currency: currentSettings.currency,
        baseCurrency: currentSettings.baseCurrency,
        language: currentSettings.language, // Keep existing language
      );

      await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.settingsSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToSaveSettings(e.toString()),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showUnsavedChangesDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.unsavedChanges),
        content: Text(loc.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              if (mounted) {
                context.pop(); // Navigate back using Go Router
              }
            },
            child: Text(loc.discard),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Just close dialog
            },
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await _saveSettings();
              if (!mounted) return;
              context.pop(); // Navigate back using Go Router
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.targetsAndAlertsHelp),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.helpRiskProfileTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(loc.helpRiskProfileText),
              const SizedBox(height: 16),
              Text(
                loc.helpAllocationTargetsTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(loc.helpAllocationTargetsText),
              const SizedBox(height: 16),
              Text(
                loc.helpMonthlyEssentialsTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(loc.helpMonthlyEssentialsText),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.gotIt),
          ),
        ],
      ),
    );
  }
}
