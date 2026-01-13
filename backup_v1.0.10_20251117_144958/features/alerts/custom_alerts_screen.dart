import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../routes.dart' show AppRouter;
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../generated/app_localizations.dart';

class CustomAlertsScreen extends ConsumerWidget {
  const CustomAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.customAlerts)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (settings) {
        if (!settings.isPro) {
          return _UpgradeGate(onUpgrade: () => context.push(AppRouter.pro));
        }
        return const _AlertsBody();
      },
    );
  }
}

class _UpgradeGate extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _UpgradeGate({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.customAlerts)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.unlockCustomAlerts,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.customAlertsDescription,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onUpgrade,
                child: Text(AppLocalizations.of(context)!.upgradeToProTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsBody extends ConsumerStatefulWidget {
  const _AlertsBody();

  @override
  ConsumerState<_AlertsBody> createState() => _AlertsBodyState();
}

class _AlertsBodyState extends ConsumerState<_AlertsBody> {
  late double _driftThreshold; // uses settings.driftThresholdPct
  late double _concentrationCap; // maps to settings.bucketCap
  late double _employerStockCap; // maps to settings.employerStockThreshold
  bool _notificationsEnabled = true;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).value!;
    _driftThreshold = settings.driftThresholdPct;
    _concentrationCap = settings.bucketCap;
    _employerStockCap = settings.employerStockThreshold;
    _notificationsEnabled = settings.notificationsEnabled;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final current = ref.read(settingsProvider).value;
    if (current == null) return;
    setState(() => _saving = true);
    try {
      final updated = Settings(
        riskBand: current.riskBand,
        monthlyEssentials: current.monthlyEssentials,
        driftThresholdPct: _driftThreshold,
        notificationsEnabled: _notificationsEnabled,
        usEquityTargetPct: current.usEquityTargetPct,
        isPro: current.isPro,
        biometricLockEnabled: current.biometricLockEnabled,
        darkModeEnabled: current.darkModeEnabled,
        colorTheme: current.colorTheme,
        liquidityBondHaircut: current.liquidityBondHaircut,
        bucketCap: _concentrationCap,
        employerStockThreshold: _employerStockCap,
        monthlyIncome: current.monthlyIncome,
        incomeMultiplierFallback: current.incomeMultiplierFallback,
        schemaVersion: current.schemaVersion,
        concentrationRiskSnoozedUntil: current.concentrationRiskSnoozedUntil,
        concentrationRiskResolvedAt: current.concentrationRiskResolvedAt,
      );
      await ref.read(settingsProvider.notifier).updateSettings(updated);
      if (mounted) {
        setState(() {
          _dirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.alertSettingsSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.failedToSave(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.customAlerts),
        actions: [
          if (_dirty && !_saving)
            TextButton(
              onPressed: _save,
              child: Text(AppLocalizations.of(context)!.save),
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader(AppLocalizations.of(context)!.thresholds),
          _sliderTile(
            label: AppLocalizations.of(context)!.driftThreshold,
            value: _driftThreshold,
            min: 0.01,
            max: 0.20,
            format: (v) => '${(v * 100).toStringAsFixed(1)}%',
            onChanged: (v) {
              setState(() => _driftThreshold = v);
              _markDirty();
            },
          ),
          _sliderTile(
            label: AppLocalizations.of(context)!.concentrationCap,
            value: _concentrationCap,
            min: 0.05,
            max: 0.50,
            format: (v) => '${(v * 100).toStringAsFixed(0)}%',
            onChanged: (v) {
              setState(() => _concentrationCap = v);
              _markDirty();
            },
          ),
          _sliderTile(
            label: AppLocalizations.of(context)!.employerStockCap,
            value: _employerStockCap,
            min: 0.05,
            max: 0.50,
            format: (v) => '${(v * 100).toStringAsFixed(0)}%',
            activeColor: Colors.orange,
            onChanged: (v) {
              setState(() => _employerStockCap = v);
              _markDirty();
            },
          ),
          const SizedBox(height: 24),
          _sectionHeader(AppLocalizations.of(context)!.notifications),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.enableAlertNotifications),
            subtitle: Text(
              AppLocalizations.of(context)!
                  .receiveAlertNotificationsDescription,
            ),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              _markDirty();
            },
          ),
          const SizedBox(height: 24),
          _sectionHeader(AppLocalizations.of(context)!.dollarImpactPreview),
          _impactCard(theme),
          const SizedBox(height: 40),
          if (_dirty && !_saving)
            FilledButton(
              onPressed: _save,
              child: Text(AppLocalizations.of(context)!.saveChanges),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
    Color? activeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(
                  format(value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min) == 0 ? null : ((max - min) * 100).round(),
              label: format(value),
              onChanged: onChanged,
              activeColor: activeColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _impactCard(ThemeData theme) {
    // Simple heuristic: show potential excess risk dollars if concentration or employer stock exceed caps.
    // (In a fuller version, we'd derive from account balances.) For now, just explanatory text.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.exampleImpact,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.exampleImpactDescription,
              style: const TextStyle(height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
