import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../data/models.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider).value;
      if (settings != null) {
        _usEquityController.text = settings.usEquityTargetPct.toString();
        // _driftThresholdController.text = settings.driftThresholdPct.toString(); // Commented out with drift alerts
        _monthlyEssentialsController.text =
            settings.monthlyEssentials.toString();
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
          title: const Text('Targets & Alerts'),
          actions: [
            if (_hasChanges) ...[
              TextButton(
                onPressed: _saveSettings,
                child: const Text('Save'),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
              tooltip: 'Help',
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
                Text('Error loading settings: $error'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(settingsProvider.notifier).reload(),
                  child: const Text('Retry'),
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
                label: const Text('Save Changes'),
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
                        'Risk Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your risk tolerance affects target allocations and recommendations.',
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
                        'Allocation Targets',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set your target allocation percentages.',
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
                    decoration: const InputDecoration(
                      labelText: 'US Equity Target %',
                      hintText: '60.0',
                      suffixText: '%',
                      helperText: 'Target percentage for US stock allocation',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a target percentage';
                      }
                      final percentage = double.tryParse(value);
                      if (percentage == null) {
                        return 'Please enter a valid number';
                      }
                      if (percentage < 0 || percentage > 100) {
                        return 'Percentage must be between 0 and 100';
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
                        'Budget & Planning',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Help us provide better recommendations.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monthly Essentials
                  TextFormField(
                    controller: _monthlyEssentialsController,
                    focusNode: _monthlyEssentialsFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Monthly Essential Expenses',
                      hintText: '5000',
                      prefixText: '\$',
                      helperText:
                          'Rent, utilities, food, insurance, minimum debt payments',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your monthly essentials';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid amount';
                      }
                      if (amount < 0) {
                        return 'Amount cannot be negative';
                      }
                      return null;
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
    switch (band) {
      case RiskBand.conservative:
        return (
          'Conservative',
          'Lower risk, steady growth. Good for those near retirement or with low risk tolerance.',
          '40% Stocks / 60% Bonds'
        );
      case RiskBand.balanced:
        return (
          'Balanced',
          'Moderate risk and growth. Balanced approach for most long-term investors.',
          '60% Stocks / 40% Bonds'
        );
      case RiskBand.growth:
        return (
          'Growth',
          'Higher risk, higher potential returns. Good for younger investors with long time horizons.',
          '80% Stocks / 20% Bonds'
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

      final updatedSettings = Settings(
        riskBand: _selectedRiskBand,
        monthlyEssentials: double.parse(_monthlyEssentialsController.text),
        driftThresholdPct:
            currentSettings.driftThresholdPct, // Keep existing value
        notificationsEnabled:
            currentSettings.notificationsEnabled, // Keep existing value
        usEquityTargetPct: double.parse(_usEquityController.text),
        isPro: currentSettings.isPro,
        biometricLockEnabled: currentSettings.biometricLockEnabled,
        darkModeEnabled: currentSettings.darkModeEnabled,
        colorTheme: currentSettings.colorTheme,
      );

      await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (mounted) {
                context.pop(); // Navigate back using Go Router
              }
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Just close dialog
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _saveSettings();
              if (mounted) {
                context.pop(); // Navigate back using Go Router
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Targets & Alerts Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Choose your comfort level with market volatility and potential returns.',
              ),
              SizedBox(height: 16),
              Text(
                'Allocation Targets',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Set target percentages for different asset classes. The dashboard will show rebalancing recommendations when your allocation differs significantly from targets.',
              ),
              SizedBox(height: 16),
              Text(
                'Monthly Essentials',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your fixed monthly expenses help us calculate emergency fund recommendations and cash allocation suggestions.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
