import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../app.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../theme.dart';
import '../../utils/premium_helper.dart';
import '../../utils/currency_formatter.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/goal_planner_service.dart';
import '../../generated/app_localizations.dart';

class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading settings: $error'),
        ),
        data: (settings) => ListView(
          children: [
            // Color Theme Section
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.colorTheme,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.chooseColorScheme,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ColorTheme.values.map((theme) {
                        final isSelected = settings.colorTheme == theme;
                        final color = AppTheme.getPrimaryColor(theme);
                        final isPro = PremiumHelper.isPro(ref);
                        final isFreeTier = theme == ColorTheme.green ||
                            theme == ColorTheme.blue;
                        final isLocked = !isPro && !isFreeTier;

                        return GestureDetector(
                          onTap: () => isLocked
                              ? _showColorThemeUpgrade(context, theme)
                              : _updateTheme(ref, theme),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? color.withValues(alpha: 0.3)
                                  : color,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle,
                                      color: isLocked
                                          ? Colors.white54
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppTheme.getColorThemeName(
                                        theme,
                                        context,
                                      ),
                                      style: TextStyle(
                                        color: isLocked
                                            ? Colors.white54
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isLocked)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: PremiumHelper.premiumBadge(
                                      context,
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Currency Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.currency,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.displayInCurrency,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        showCurrencyPicker(
                          context: context,
                          showFlag: true,
                          showCurrencyName: true,
                          showCurrencyCode: true,
                          onSelect: (Currency currency) {
                            _updateCurrency(ref, currency.code);
                          },
                          favorite: ['USD', 'EUR', 'GBP', 'JPY', 'CNY'],
                        );
                      },
                      icon: Text(
                        CurrencyFormatter.getCurrency(settings.currency)
                                ?.flag ??
                            '🌍',
                        style: const TextStyle(fontSize: 24),
                      ),
                      label: Text(
                        '${CurrencyFormatter.getCurrency(settings.currency)?.name ?? 'US Dollar'} (${settings.currency})',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Currency Conversion Preview
                    _CurrencyConversionPreview(
                      baseCurrency: settings.baseCurrency,
                      displayCurrency: settings.currency,
                    ),
                  ],
                ),
              ),
            ),

            // Language Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.language,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.chooseLanguage,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: settings.language ?? 'en',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Row(
                            children: [
                              const Text(
                                '🇺🇸',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.english),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'hi',
                          child: Row(
                            children: [
                              const Text(
                                '🇮🇳',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.hindi),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'bn',
                          child: Row(
                            children: [
                              const Text(
                                '🇧🇩',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.bengali),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Row(
                            children: [
                              const Text(
                                '🇸🇩',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.arabic),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'fa',
                          child: Row(
                            children: [
                              const Text(
                                '🇮🇷',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.persian),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Row(
                            children: [
                              const Text(
                                '🇫🇷',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(AppLocalizations.of(context)!.french),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'request',
                          child: Row(
                            children: [
                              const Icon(Icons.email, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.requestLanguage,
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'request') {
                          _requestLanguageSupport(context);
                        } else if (value != null) {
                          _updateLanguage(ref, value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Dark Mode Toggle
            const _HouseholdProfilesCard(),

            // Dark Mode Toggle
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: Text(AppLocalizations.of(context)!.darkMode),
                subtitle: Text(AppLocalizations.of(context)!.useDarkTheme),
                value: settings.darkModeEnabled,
                onChanged: (value) => _updateDarkMode(ref, value),
              ),
            ),

            // Debug Pro Toggle (only visible in debug mode)
            if (kDebugMode) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange.shade50,
                child: SwitchListTile(
                  secondary: Icon(
                    settings.isPro
                        ? Icons.workspace_premium
                        : Icons.star_outline,
                    color: settings.isPro ? Colors.amber : Colors.grey,
                  ),
                  title: Row(
                    children: [
                      Text(AppLocalizations.of(context)!.proStatus),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DEBUG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    settings.isPro
                        ? AppLocalizations.of(context)!.testingAsProUser
                        : AppLocalizations.of(context)!.testingAsFreeUser,
                  ),
                  value: settings.isPro,
                  onChanged: (value) => _updateProStatus(ref, value),
                ),
              ),
            ],

            // Other Settings
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Diversification Mode
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: Text(
                      AppLocalizations.of(context)!.internationalExposure,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!
                          .controlInternationalExposure,
                    ),
                    onTap: null,
                  ),
                  RadioGroup<String>(
                    groupValue: settings.globalDiversificationMode,
                    onChanged: (v) {
                      if (v != null) {
                        _updateDiversificationMode(ref, v);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'standard',
                          title: Text(AppLocalizations.of(context)!.standard),
                          subtitle: Text(
                            AppLocalizations.of(context)!
                                .defaultPolicyPenalizeLargeDeviations,
                          ),
                        ),
                        RadioListTile<String>(
                          value: 'light',
                          title: Text(AppLocalizations.of(context)!.light),
                          subtitle: Text(
                            AppLocalizations.of(context)!.lessPunitive,
                          ),
                        ),
                        RadioListTile<String>(
                          value: 'off',
                          title: Text(AppLocalizations.of(context)!.offMute),
                          subtitle: Text(
                            AppLocalizations.of(context)!
                                .excludeInternationalExposure,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(AppLocalizations.of(context)!.targetsAndAlerts),
                    subtitle: Text(
                      AppLocalizations.of(context)!.setTargetsAndThresholds,
                    ),
                    onTap: () => context.push('/targets/detail'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_upload),
                    title: Text(AppLocalizations.of(context)!.importCSV),
                    subtitle: Text(
                      AppLocalizations.of(context)!.importAccountsDebtsIncome,
                    ),
                    onTap: () => context.push('/import/csv'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: Text(AppLocalizations.of(context)!.importAndExport),
                    subtitle:
                        Text(AppLocalizations.of(context)!.backupRestoreData),
                    onTap: () => context.push('/export'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: Text(AppLocalizations.of(context)!.proFeatures),
                    subtitle: Text(
                      AppLocalizations.of(context)!.unlockAdvancedFeatures,
                    ),
                    onTap: () => context.push('/pro'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(AppLocalizations.of(context)!.about),
                    subtitle: Text(
                      AppLocalizations.of(context)!.appInfoAndDisclaimers,
                    ),
                    onTap: () => context.push('/about'),
                  ),
                ],
              ),
            ),

            // Legal & Privacy Section
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: Text(AppLocalizations.of(context)!.privacyPolicy),
                    subtitle:
                        Text(AppLocalizations.of(context)!.howWeProtectData),
                    trailing: const Icon(Icons.open_in_new, size: 20),
                    onTap: () => _launchURL(
                      'https://platinummorgan.github.io/rebalance/privacy.html',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(AppLocalizations.of(context)!.termsOfService),
                    subtitle: Text(
                      AppLocalizations.of(context)!.legalTermsAndConditions,
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 20),
                    onTap: () => _launchURL(
                      'https://platinummorgan.github.io/rebalance/terms_of_service.html',
                    ),
                  ),
                ],
              ),
            ),

            // Feedback Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.feedback),
                title: Text(AppLocalizations.of(context)!.sendFeedback),
                subtitle: Text(
                  AppLocalizations.of(context)!.shareThoughtsAndSuggestions,
                ),
                trailing: const Icon(Icons.open_in_new, size: 20),
                onTap: () => _launchURL(
                  'mailto:admin@ripstuff.net?subject=Rebalance%20App%20Feedback',
                ),
              ),
            ),

            // Exit App Section
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => _showExitConfirmation(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.exit_to_app,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.exitApp,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.closeApplication,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.exitApp),
        content: Text(AppLocalizations.of(context)!.areYouSureExit),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop(); // Exit the app
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.exit),
          ),
        ],
      ),
    );
  }

  void _updateTheme(WidgetRef ref, ColorTheme theme) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings != null) {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
        isPro: currentSettings.isPro,
        biometricLockEnabled: currentSettings.biometricLockEnabled,
        darkModeEnabled: currentSettings.darkModeEnabled,
        colorTheme: theme,
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
        language: currentSettings.language,
      );
      settingsNotifier.updateSettings(updatedSettings);
    }
  }

  void _showColorThemeUpgrade(BuildContext context, ColorTheme theme) {
    PremiumHelper.showUpgradeDialog(
      context,
      feature: '${AppTheme.getColorThemeName(theme, context)} Theme',
      description:
          'Unlock all color themes with Rebalance Pro! Free users get Green and Blue themes.',
    );
  }

  void _updateDarkMode(WidgetRef ref, bool enabled) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings != null) {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
        isPro: currentSettings.isPro,
        biometricLockEnabled: currentSettings.biometricLockEnabled,
        darkModeEnabled: enabled,
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
        language: currentSettings.language,
      );
      settingsNotifier.updateSettings(updatedSettings);
    }
  }

  void _updateProStatus(WidgetRef ref, bool isPro) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings != null) {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
        isPro: isPro, // Toggle Pro status for testing
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
        language: currentSettings.language,
        proBannerDismissed: isPro ? false : currentSettings.proBannerDismissed,
      );
      settingsNotifier.updateSettings(updatedSettings);
    }
  }

  void _updateCurrency(WidgetRef ref, String currency) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings != null) {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
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
        currency: currency, // Update currency
        baseCurrency: currentSettings.baseCurrency, // Preserve baseCurrency
        language: currentSettings.language,
      );
      settingsNotifier.updateSettings(updatedSettings);
    }
  }

  void _updateLanguage(WidgetRef ref, String language) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings != null) {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
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
        language: language, // Update language
      );
      settingsNotifier.updateSettings(updatedSettings);
    }
  }

  void _requestLanguageSupport(BuildContext context) async {
    const String emailAddress = 'support@platovalabs.com';
    final String subject = Uri.encodeComponent('Language Support Request');
    final String body = Uri.encodeComponent(
      'I would like to request support for the following language:\n\nLanguage: \nRegion: \n\nThank you!',
    );

    final Uri emailUri =
        Uri.parse('mailto:$emailAddress?subject=$subject&body=$body');

    try {
      if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open email. Please email support@platovalabs.com',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email. Please email support@platovalabs.com',
            ),
          ),
        );
      }
    }
  }

  void _updateDiversificationMode(WidgetRef ref, String mode) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings != null) {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
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
        globalDiversificationMode: mode,
        intlTargetOverride: currentSettings.intlTargetOverride,
        intlTolerancePct: currentSettings.intlTolerancePct,
        intlFloorPct: currentSettings.intlFloorPct,
        intlPenaltyScale: currentSettings.intlPenaltyScale,
        financialHealthBaseline: currentSettings.financialHealthBaseline,
        financialHealthGlobalScale: currentSettings.financialHealthGlobalScale,
        currency: currentSettings.currency,
        baseCurrency: currentSettings.baseCurrency,
        language: currentSettings.language,
      );
      settingsNotifier.updateSettings(updatedSettings);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      // For mailto links, don't use externalApplication mode
      final mode = urlString.startsWith('mailto:')
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication;

      if (!await launchUrl(url, mode: mode)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}

class _HouseholdProfilesCard extends ConsumerStatefulWidget {
  const _HouseholdProfilesCard();

  @override
  ConsumerState<_HouseholdProfilesCard> createState() =>
      _HouseholdProfilesCardState();
}

class _HouseholdProfilesCardState extends ConsumerState<_HouseholdProfilesCard> {
  List<HouseholdProfile> _profiles = const [];
  List<HouseholdGoal> _goals = const [];
  Map<String, HouseholdProfileFinancialSummary> _profileSummaries = const {};
  Map<String, GoalPlannerResult> _goalPlanInsights = const {};
  String? _activeProfileId;
  int _goalPlannerHorizonYears = 10;
  double _goalPlannerTargetConfidence = 0.75;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profiles = await RepositoryService.getHouseholdProfiles();
      final activeProfileId =
          await RepositoryService.getActiveHouseholdProfileId();
      final profileSummaries =
          await RepositoryService.getHouseholdProfileFinancialSummaries();
      final goals = await RepositoryService.getAllHouseholdGoals();
      final settings = ref.read(settingsProvider).valueOrNull;
      final goalPlanInsights = _buildGoalPlanInsights(
        goals: goals,
        activeProfileId: activeProfileId,
        profileSummaries: profileSummaries,
        monthlyEssentials: settings?.monthlyEssentials ?? 0,
        horizonYears: _goalPlannerHorizonYears,
        targetConfidence: _goalPlannerTargetConfidence,
      );
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _goals = goals;
        _profileSummaries = profileSummaries;
        _activeProfileId = activeProfileId;
        _goalPlanInsights = goalPlanInsights;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _setActiveProfile(String? profileId) async {
    final l10n = AppLocalizations.of(context)!;
    if (profileId == null || profileId == _activeProfileId) return;
    try {
      await RepositoryService.setActiveHouseholdProfile(profileId);
      await Future.wait([
        ref.read(accountsProvider.notifier).reload(),
        ref.read(liabilitiesProvider.notifier).reload(),
        ref.read(incomesProvider.notifier).reload(),
        ref.read(expensesProvider.notifier).reload(),
      ]);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.householdActiveProfileUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.householdFailedToUpdateProfile(e.toString())),
        ),
      );
    }
  }

  HouseholdProfileFinancialSummary _summaryFor(String profileId) {
    return _profileSummaries[profileId] ??
        const HouseholdProfileFinancialSummary(
          counts: HouseholdProfileFinancialCounts(
            accounts: 0,
            liabilities: 0,
            incomes: 0,
            expenses: 0,
          ),
          totalAssets: 0,
          totalLiabilities: 0,
          monthlyIncome: 0,
          monthlyExpenses: 0,
        );
  }

  String _countsLabel(HouseholdProfileFinancialCounts counts) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.householdCountsCompact(
      counts.accounts,
      counts.liabilities,
      counts.incomes,
      counts.expenses,
      counts.goals,
    );
  }

  HouseholdProfile? _activeProfile() {
    final activeProfileId = _activeProfileId;
    if (activeProfileId == null) return null;
    for (final profile in _profiles) {
      if (profile.id == activeProfileId) {
        return profile;
      }
    }
    return null;
  }

  int _totalMovableFromOtherProfiles() {
    final activeProfileId = _activeProfileId;
    if (activeProfileId == null) return 0;
    var totalMovable = 0;
    for (final profile in _profiles) {
      if (profile.id == activeProfileId) continue;
      final counts = _summaryFor(profile.id).counts;
      totalMovable += counts.accounts +
          counts.liabilities +
          counts.incomes +
          counts.expenses +
          _ownedGoalCountForProfile(profile.id);
    }
    return totalMovable;
  }

  String _profileSummaryLabel({
    required String profileId,
    required String currency,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summaryFor(profileId);
    final countsLabel = _countsLabel(summary.counts);
    final netWorthLabel = CurrencyFormatter.format(summary.netWorth, currency);
    return '$countsLabel • ${l10n.netWorth}: $netWorthLabel';
  }

  int _ownedGoalCountForProfile(String profileId) {
    var count = 0;
    for (final goal in _goals) {
      if (!goal.isShared && goal.ownerProfileId == profileId) {
        count++;
      }
    }
    return count;
  }

  bool _hasBlockingDataForProfileDelete(String profileId) {
    final counts = _summaryFor(profileId).counts;
    final hasCoreFinancialData =
        counts.accounts > 0 || counts.liabilities > 0 || counts.incomes > 0 || counts.expenses > 0;
    if (hasCoreFinancialData) return true;
    return _ownedGoalCountForProfile(profileId) > 0;
  }

  List<HouseholdGoal> _goalsForActiveProfile() {
    final activeProfileId = _activeProfileId;
    if (activeProfileId == null) return const [];
    final goals = _goals
        .where(
          (goal) => goal.isShared || goal.ownerProfileId == activeProfileId,
        )
        .toList();
    goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return goals;
  }

  String _goalScopeLabel(HouseholdGoal goal) {
    final l10n = AppLocalizations.of(context)!;
    if (goal.isShared) return l10n.householdGoalScopeShared;
    String? profileName;
    for (final profile in _profiles) {
      if (profile.id == goal.ownerProfileId) {
        profileName = profile.name;
        break;
      }
    }
    if (profileName == null || profileName.isEmpty) {
      return l10n.householdGoalScopeProfileUnknown;
    }
    return l10n.householdGoalScopeProfile(profileName);
  }

  Map<String, double> _normalizedGoalSplits(HouseholdGoal goal) {
    final profileIds = _profiles.map((p) => p.id).toList();
    if (profileIds.isEmpty) return const {};
    final raw = goal.contributionSplits ?? const <String, double>{};
    final sanitized = <String, double>{};
    for (final id in profileIds) {
      final value = raw[id];
      if (value == null || value.isNaN || value.isInfinite || value < 0) {
        continue;
      }
      sanitized[id] = value;
    }
    var sum = 0.0;
    for (final value in sanitized.values) {
      sum += value;
    }
    if (sum <= 0) {
      final equal = 1.0 / profileIds.length;
      return {for (final id in profileIds) id: equal};
    }
    return {
      for (final id in profileIds) id: (sanitized[id] ?? 0.0) / sum,
    };
  }

  String _goalSplitPreview(HouseholdGoal goal) {
    if (!goal.isShared) return '';
    final splits = _normalizedGoalSplits(goal);
    final parts = <String>[];
    final entries = splits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in entries) {
      if (entry.value <= 0) continue;
      String? profileName;
      for (final profile in _profiles) {
        if (profile.id == entry.key) {
          profileName = profile.name;
          break;
        }
      }
      if (profileName == null) continue;
      parts.add('$profileName ${(entry.value * 100).toStringAsFixed(0)}%');
      if (parts.length >= 3) break;
    }
    if (parts.isEmpty) return '';
    final l10n = AppLocalizations.of(context)!;
    return l10n.householdGoalSplitPreview(parts.join(', '));
  }

  String _goalProgressSummary(HouseholdGoal goal, String currency) {
    final l10n = AppLocalizations.of(context)!;
    final target = goal.targetAmount <= 0 ? 0.0 : goal.targetAmount;
    final current = goal.currentAmount.clamp(0, double.infinity).toDouble();
    final percent = target <= 0
        ? 0.0
        : (current / target * 100).clamp(0, 9999).toDouble();
    return l10n.householdGoalProgressSummary(
      CurrencyFormatter.format(current, currency),
      CurrencyFormatter.format(target, currency),
      percent.toStringAsFixed(1),
    );
  }

  Map<String, GoalPlannerResult> _buildGoalPlanInsights({
    required List<HouseholdGoal> goals,
    required String? activeProfileId,
    required Map<String, HouseholdProfileFinancialSummary> profileSummaries,
    required double monthlyEssentials,
    required int horizonYears,
    required double targetConfidence,
  }) {
    if (activeProfileId == null) return const {};

    final activeGoals = goals
        .where((goal) => goal.isShared || goal.ownerProfileId == activeProfileId)
        .toList();
    if (activeGoals.isEmpty) return const {};

    final summary = profileSummaries[activeProfileId];
    final monthlyIncome = summary?.monthlyIncome ?? 0.0;
    final trackedMonthlyExpenses = summary?.monthlyExpenses ?? 0.0;
    final effectiveMonthlyExpenses =
        math.max(trackedMonthlyExpenses, monthlyEssentials).toDouble();
    final monthlySurplus =
        math.max(monthlyIncome - effectiveMonthlyExpenses, 0.0).toDouble();

    final remainingByGoal = <String, double>{};
    var totalRemaining = 0.0;
    for (final goal in activeGoals) {
      final remaining =
          math.max(goal.targetAmount - goal.currentAmount, 0.0).toDouble();
      remainingByGoal[goal.id] = remaining;
      totalRemaining += remaining;
    }

    final now = DateTime.now();
    final targetDate = DateTime(now.year + horizonYears, now.month, 1);

    final insights = <String, GoalPlannerResult>{};
    for (var i = 0; i < activeGoals.length; i++) {
      final goal = activeGoals[i];
      if (goal.targetAmount <= 0) continue;

      final remaining = remainingByGoal[goal.id] ?? 0.0;
      double assumedMonthlyContribution;
      if (monthlySurplus <= 0) {
        assumedMonthlyContribution = 0;
      } else if (totalRemaining > 0) {
        assumedMonthlyContribution = monthlySurplus * (remaining / totalRemaining);
      } else {
        assumedMonthlyContribution = monthlySurplus / activeGoals.length;
      }

      try {
        insights[goal.id] = GoalPlannerService.calculateForHouseholdGoal(
          goal: goal,
          monthlyContribution: assumedMonthlyContribution,
          asOf: now,
          targetDate: targetDate,
          simulations: 450,
          desiredConfidence: targetConfidence,
          seed: 42 + (i * 13),
        );
      } catch (_) {
        // Ignore invalid planner inputs for specific goals and continue.
      }
    }

    return insights;
  }

  void _refreshGoalPlanInsights() {
    final settings = ref.read(settingsProvider).valueOrNull;
    setState(() {
      _goalPlanInsights = _buildGoalPlanInsights(
        goals: _goals,
        activeProfileId: _activeProfileId,
        profileSummaries: _profileSummaries,
        monthlyEssentials: settings?.monthlyEssentials ?? 0,
        horizonYears: _goalPlannerHorizonYears,
        targetConfidence: _goalPlannerTargetConfidence,
      );
    });
  }

  Color _goalConfidenceColor(GoalPlannerResult result) {
    final confidence = result.successProbability;
    if (confidence >= result.desiredConfidence) return Colors.green;
    if (confidence >= result.desiredConfidence * 0.75) return Colors.orange;
    return Colors.red;
  }

  Future<void> _upsertGoal({HouseholdGoal? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider).valueOrNull;
    final currency = settings?.currency ?? 'USD';
    final isEditing = existing != null;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final targetController = TextEditingController(
      text: existing?.targetAmount.toStringAsFixed(2) ?? '',
    );
    final currentController = TextEditingController(
      text: existing?.currentAmount.toStringAsFixed(2) ?? '',
    );
    bool isShared = existing?.isShared ?? false;
    String selectedOwner = existing?.ownerProfileId ??
        (_activeProfileId ?? (_profiles.isNotEmpty ? _profiles.first.id : ''));
    String? dialogError;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? l10n.householdEditGoalTitle : l10n.householdAddGoalTitle,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: !isEditing,
                      decoration: InputDecoration(
                        labelText: l10n.householdGoalNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.householdGoalTargetAmountLabel,
                        prefixText:
                            '${CurrencyFormatter.getCurrency(currency)?.symbol ?? ''} ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: currentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.householdGoalCurrentAmountLabel,
                        prefixText:
                            '${CurrencyFormatter.getCurrency(currency)?.symbol ?? ''} ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.householdGoalSharedToggle),
                      value: isShared,
                      onChanged: (value) {
                        setDialogState(() {
                          isShared = value;
                          dialogError = null;
                        });
                      },
                    ),
                    if (!isShared) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedOwner.isEmpty ? null : selectedOwner,
                        decoration: InputDecoration(
                          labelText: l10n.householdGoalOwnerProfileLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: _profiles
                            .map(
                              (profile) => DropdownMenuItem<String>(
                                value: profile.id,
                                child: Text(profile.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedOwner = value;
                            dialogError = null;
                          });
                        },
                      ),
                    ],
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        dialogError = l10n.householdGoalNameRequired;
                      });
                      return;
                    }
                    final target = double.tryParse(targetController.text.trim());
                    if (target == null || target < 0) {
                      setDialogState(() {
                        dialogError = l10n.householdGoalTargetInvalid;
                      });
                      return;
                    }
                    final current = double.tryParse(currentController.text.trim());
                    if (current == null || current < 0) {
                      setDialogState(() {
                        dialogError = l10n.householdGoalCurrentInvalid;
                      });
                      return;
                    }
                    if (!isShared && selectedOwner.isEmpty) {
                      setDialogState(() {
                        dialogError = l10n.householdGoalOwnerRequired;
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(isEditing ? l10n.save : l10n.add),
                ),
              ],
            );
          },
        );
      },
    );

    final name = nameController.text.trim();
    final targetAmount = double.tryParse(targetController.text.trim()) ?? -1;
    final currentAmount = double.tryParse(currentController.text.trim()) ?? -1;
    nameController.dispose();
    targetController.dispose();
    currentController.dispose();

    if (saved != true) return;

    try {
      if (existing == null) {
        await RepositoryService.addHouseholdGoal(
          name: name,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          isShared: isShared,
          ownerProfileId: isShared ? null : selectedOwner,
        );
      } else {
        existing.name = name;
        existing.targetAmount = targetAmount;
        existing.currentAmount = currentAmount;
        existing.isShared = isShared;
        existing.ownerProfileId = isShared ? null : selectedOwner;
        await RepositoryService.saveHouseholdGoal(existing);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      final errorText = existing == null
          ? l10n.householdGoalFailedToAdd(e.toString())
          : l10n.householdGoalFailedToUpdate(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
    }
  }

  Future<void> _addGoal() async => _upsertGoal();

  Future<void> _editGoal(HouseholdGoal goal) async => _upsertGoal(existing: goal);

  Future<void> _editGoalSplits(HouseholdGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    if (!goal.isShared || _profiles.isEmpty) return;

    final splits = _normalizedGoalSplits(goal);
    final controllers = <String, TextEditingController>{
      for (final profile in _profiles)
        profile.id: TextEditingController(
          text: ((splits[profile.id] ?? 0) * 100).toStringAsFixed(1),
        ),
    };
    String? dialogError;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.householdGoalEditSplitsTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final profile in _profiles) ...[
                      TextField(
                        controller: controllers[profile.id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: profile.name,
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (dialogError != null) {
                            setDialogState(() {
                              dialogError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (dialogError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    var total = 0.0;
                    for (final controller in controllers.values) {
                      final value = double.tryParse(controller.text.trim()) ?? -1;
                      if (value < 0) {
                        setDialogState(() {
                          dialogError = l10n.householdGoalSplitNeedPositive;
                        });
                        return;
                      }
                      total += value;
                    }
                    if (total <= 0) {
                      setDialogState(() {
                        dialogError = l10n.householdGoalSplitNeedPositive;
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final normalized = <String, double>{};
      var total = 0.0;
      for (final profile in _profiles) {
        final value = double.tryParse(controllers[profile.id]!.text.trim()) ?? 0;
        total += value;
        normalized[profile.id] = value;
      }
      if (total > 0) {
        for (final id in normalized.keys.toList()) {
          normalized[id] = normalized[id]! / total;
        }
      }
      try {
        goal.contributionSplits = normalized;
        await RepositoryService.saveHouseholdGoal(goal);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.householdGoalFailedToUpdateSplits(e.toString())),
            ),
          );
        }
      }
    }

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _deleteGoal(HouseholdGoal goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdGoalDeleteTitle),
        content: Text(l10n.householdGoalDeleteMessage(goal.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await RepositoryService.deleteHouseholdGoal(goal.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.householdGoalFailedToDelete(e.toString()))),
      );
    }
  }

  Future<void> _addProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdAddProfileTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.householdProfileNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.trim().isEmpty) return;
    try {
      await RepositoryService.addHouseholdProfile(name);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.householdFailedToAddProfile(e.toString()))),
      );
    }
  }

  Future<void> _renameProfile(HouseholdProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: profile.name);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdRenameProfileTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.householdProfileNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();

    if (updatedName == null || updatedName.trim().isEmpty) return;
    if (updatedName.trim() == profile.name) return;

    try {
      await RepositoryService.renameHouseholdProfile(profile.id, updatedName);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.householdFailedToRenameProfile(e.toString())),
        ),
      );
    }
  }

  Future<void> _deleteProfile(HouseholdProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdDeleteProfileTitle),
        content: Text(
          l10n.householdDeleteProfileDescription(profile.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await RepositoryService.deleteHouseholdProfile(profile.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.householdFailedToDeleteProfile(e.toString())),
        ),
      );
    }
  }

  Future<void> _moveDataBetweenProfiles() async {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.read(settingsProvider).valueOrNull?.currency ?? 'USD';
    if (_profiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.householdCreateAtLeastTwoProfiles),
        ),
      );
      return;
    }

    String fromProfileId = _activeProfileId ?? _profiles.first.id;
    String toProfileId = _profiles
        .firstWhere(
          (profile) => profile.id != fromProfileId,
          orElse: () => _profiles.first,
        )
        .id;
    bool moveAccounts = true;
    bool moveLiabilities = true;
    bool moveIncomes = true;
    bool moveExpenses = true;
    bool moveGoals = true;
    String? dialogError;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final targetOptions = _profiles
                .where((profile) => profile.id != fromProfileId)
                .toList();
            if (targetOptions.isNotEmpty &&
                !targetOptions.any((p) => p.id == toProfileId)) {
              toProfileId = targetOptions.first.id;
            }

            return AlertDialog(
              title: Text(l10n.householdMoveDataTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.householdMoveDataDescription,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: fromProfileId,
                    decoration: InputDecoration(
                      labelText: l10n.householdMoveFromProfileLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: _profiles
                        .map(
                          (profile) => DropdownMenuItem<String>(
                            value: profile.id,
                            child: Text(
                              l10n.householdProfileOptionLabel(
                                profile.name,
                                _profileSummaryLabel(
                                  profileId: profile.id,
                                  currency: currency,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        fromProfileId = value;
                        dialogError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: toProfileId,
                    decoration: InputDecoration(
                      labelText: l10n.householdMoveToProfileLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: targetOptions
                        .map(
                          (profile) => DropdownMenuItem<String>(
                            value: profile.id,
                            child: Text(
                              l10n.householdProfileOptionLabel(
                                profile.name,
                                _profileSummaryLabel(
                                  profileId: profile.id,
                                  currency: currency,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        toProfileId = value;
                        dialogError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.householdMoveDataTypesLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: moveAccounts,
                    title: Text(
                      '${l10n.accounts} (${_summaryFor(fromProfileId).counts.accounts})',
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        moveAccounts = value;
                        dialogError = null;
                      });
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: moveLiabilities,
                    title: Text(
                      '${l10n.liabilities} (${_summaryFor(fromProfileId).counts.liabilities})',
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        moveLiabilities = value;
                        dialogError = null;
                      });
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: moveIncomes,
                    title: Text(
                      '${l10n.income} (${_summaryFor(fromProfileId).counts.incomes})',
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        moveIncomes = value;
                        dialogError = null;
                      });
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: moveExpenses,
                    title: Text(
                      '${l10n.expenses} (${_summaryFor(fromProfileId).counts.expenses})',
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        moveExpenses = value;
                        dialogError = null;
                      });
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: moveGoals,
                    title: Text(
                      '${l10n.householdDataTypeGoals} (${_ownedGoalCountForProfile(fromProfileId)})',
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        moveGoals = value;
                        dialogError = null;
                      });
                    },
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (fromProfileId == toProfileId) {
                      setDialogState(() {
                        dialogError = l10n.householdMoveProfilesMustDiffer;
                      });
                      return;
                    }
                    if (!moveAccounts &&
                        !moveLiabilities &&
                        !moveIncomes &&
                        !moveExpenses &&
                        !moveGoals) {
                      setDialogState(() {
                        dialogError = l10n.householdMoveSelectAtLeastOneType;
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(l10n.transfer),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      final result = await RepositoryService.moveFinancialDataToProfile(
        fromProfileId: fromProfileId,
        toProfileId: toProfileId,
        moveAccounts: moveAccounts,
        moveLiabilities: moveLiabilities,
        moveIncomes: moveIncomes,
        moveExpenses: moveExpenses,
        moveGoals: moveGoals,
      );
      await Future.wait([
        ref.read(accountsProvider.notifier).reload(),
        ref.read(liabilitiesProvider.notifier).reload(),
        ref.read(incomesProvider.notifier).reload(),
        ref.read(expensesProvider.notifier).reload(),
      ]);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.householdMovedRecordsSummary(
              result.totalMoved,
              result.accountsMoved,
              result.liabilitiesMoved,
              result.incomesMoved,
              result.expensesMoved,
              result.goalsMoved,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.householdFailedToMoveData(e.toString()))),
      );
    }
  }

  Future<void> _moveAllDataToActiveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final activeProfileId = _activeProfileId;
    if (activeProfileId == null) return;

    HouseholdProfile? activeProfile;
    for (final profile in _profiles) {
      if (profile.id == activeProfileId) {
        activeProfile = profile;
        break;
      }
    }
    if (activeProfile == null) return;
    final active = activeProfile;

    final totalMovable = _totalMovableFromOtherProfiles();

    if (totalMovable <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.householdMoveAllNoData)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdMoveAllConfirmTitle),
        content: Text(
          l10n.householdMoveAllConfirmMessage(
            totalMovable,
            active.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.transfer),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await RepositoryService.moveAllFinancialDataToProfile(
        targetProfileId: active.id,
      );
      await Future.wait([
        ref.read(accountsProvider.notifier).reload(),
        ref.read(liabilitiesProvider.notifier).reload(),
        ref.read(incomesProvider.notifier).reload(),
        ref.read(expensesProvider.notifier).reload(),
      ]);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.householdMovedRecordsSummary(
              result.totalMoved,
              result.accountsMoved,
              result.liabilitiesMoved,
              result.incomesMoved,
              result.expensesMoved,
              result.goalsMoved,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.householdFailedToMoveAllData(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final currency = settings?.currency ?? 'USD';
    final activeProfile = _activeProfile();
    final activeSummary = activeProfile == null
        ? const HouseholdProfileFinancialSummary(
            counts: HouseholdProfileFinancialCounts(
              accounts: 0,
              liabilities: 0,
              incomes: 0,
              expenses: 0,
            ),
            totalAssets: 0,
            totalLiabilities: 0,
            monthlyIncome: 0,
            monthlyExpenses: 0,
          )
        : _summaryFor(activeProfile.id);
    final movableFromOtherProfiles = _totalMovableFromOtherProfiles();
    final activeGoals = _goalsForActiveProfile();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.householdProfilesBetaTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addProfile,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.householdProfilesDescription,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.householdActiveProfileLabel}: ${activeProfile?.name ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(_countsLabel(activeSummary.counts)),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.netWorth}: ${CurrencyFormatter.format(activeSummary.netWorth, currency)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: _activeProfileId,
                decoration: InputDecoration(
                  labelText: l10n.householdActiveProfileLabel,
                  border: const OutlineInputBorder(),
                ),
                items: _profiles
                    .map(
                      (profile) => DropdownMenuItem<String>(
                        value: profile.id,
                        child: Text(
                          l10n.householdProfileOptionLabel(
                            profile.name,
                            _profileSummaryLabel(
                              profileId: profile.id,
                              currency: currency,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _setActiveProfile,
              ),
              const SizedBox(height: 12),
              if (_profiles.isEmpty)
                Text(l10n.householdNoProfilesAvailable)
              else
                Column(
                  children: _profiles
                      .map(
                        (profile) {
                          final summary = _summaryFor(profile.id);
                          final counts = summary.counts;
                          final deleteDisabled = _profiles.length <= 1 ||
                              _hasBlockingDataForProfileDelete(profile.id);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              profile.id == _activeProfileId
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                            ),
                            title: Text(profile.name),
                            subtitle: Text(
                              '${profile.id == _activeProfileId ? l10n.householdStatusActive : l10n.householdStatusInactive} • '
                              '${_countsLabel(counts)} • '
                              '${l10n.netWorth}: ${CurrencyFormatter.format(summary.netWorth, currency)}',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n.householdRenameProfileTitle,
                                  onPressed: () => _renameProfile(profile),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: deleteDisabled
                                      ? (_profiles.length <= 1
                                          ? l10n.householdDeleteTooltipAtLeastOne
                                          : l10n.householdDeleteTooltipMoveDataFirst)
                                      : l10n.householdDeleteTooltipDelete,
                                  onPressed: deleteDisabled
                                      ? null
                                      : () => _deleteProfile(profile),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      .toList(),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.householdGoalsSectionTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _profiles.isEmpty ? null : _addGoal,
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(l10n.add),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal Confidence Planner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 15]
                          .map(
                            (years) => ChoiceChip(
                              label: Text('$years yr'),
                              selected: _goalPlannerHorizonYears == years,
                              onSelected: (selected) {
                                if (!selected) return;
                                _goalPlannerHorizonYears = years;
                                _refreshGoalPlanInsights();
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Target Confidence: ${(_goalPlannerTargetConfidence * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _goalPlannerTargetConfidence,
                      min: 0.60,
                      max: 0.90,
                      divisions: 6,
                      label: '${(_goalPlannerTargetConfidence * 100).round()}%',
                      onChanged: (value) {
                        setState(() {
                          _goalPlannerTargetConfidence = value;
                        });
                      },
                      onChangeEnd: (_) => _refreshGoalPlanInsights(),
                    ),
                  ],
                ),
              ),
              if (activeGoals.isEmpty)
                Text(
                  l10n.householdGoalNoGoalsForActive,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                )
              else
                Column(
                  children: activeGoals
                      .map(
                        (goal) {
                          final progressRatio = goal.targetAmount <= 0
                              ? 0.0
                              : (goal.currentAmount / goal.targetAmount)
                                  .clamp(0.0, 1.0);
                          final splitPreview = _goalSplitPreview(goal);
                          final goalPlan = _goalPlanInsights[goal.id];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              goal.isShared ? Icons.groups : Icons.person_outline,
                              size: 18,
                            ),
                            title: Text(goal.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_goalScopeLabel(goal)} • ${CurrencyFormatter.format(goal.targetAmount, currency)}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _goalProgressSummary(goal, currency),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(value: progressRatio),
                                if (goalPlan != null) ...[
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (context) {
                                      final confidencePct =
                                          (goalPlan.successProbability * 100)
                                              .toStringAsFixed(1);
                                      final targetPct =
                                          (goalPlan.desiredConfidence * 100)
                                              .toStringAsFixed(0);
                                      final confidenceColor =
                                          _goalConfidenceColor(goalPlan);
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: confidenceColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: confidenceColor.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Confidence $confidencePct% (target $targetPct%)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: confidenceColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            LinearProgressIndicator(
                                              value: goalPlan.successProbability.clamp(0.0, 1.0),
                                              color: confidenceColor,
                                              backgroundColor: confidenceColor.withValues(alpha: 0.15),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Planned monthly: ${CurrencyFormatter.format(goalPlan.assumedMonthlyContribution, currency)} • '
                                              'Required: ${CurrencyFormatter.format(goalPlan.requiredMonthlyContribution, currency)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              'Horizon: ${(_goalPlannerHorizonYears)} years • Sim: ${goalPlan.simulations}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (splitPreview.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    splitPreview,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n.edit,
                                  onPressed: () => _editGoal(goal),
                                ),
                                if (goal.isShared)
                                  IconButton(
                                    icon: const Icon(Icons.pie_chart_outline),
                                    tooltip: l10n.householdGoalEditSplitsTooltip,
                                    onPressed: () => _editGoalSplits(goal),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.delete,
                                  onPressed: () => _deleteGoal(goal),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      .toList(),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _moveDataBetweenProfiles,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l10n.householdMoveDataTitle),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: movableFromOtherProfiles > 0
                      ? _moveAllDataToActiveProfile
                      : null,
                  icon: const Icon(Icons.merge_type),
                  label: Text(l10n.householdMoveAllToActiveButton),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    l10n.householdMovableFromOtherProfiles(
                      movableFromOtherProfiles,
                    ),
                  ),
                  avatar: const Icon(Icons.stacked_bar_chart, size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget that shows currency conversion preview for user's total assets
class _CurrencyConversionPreview extends ConsumerWidget {
  final String baseCurrency;
  final String displayCurrency;

  const _CurrencyConversionPreview({
    required this.baseCurrency,
    required this.displayCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRateService = ref.watch(exchangeRateServiceProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) {
        final totalAssets = accounts.fold<double>(
          0.0,
          (sum, account) => sum + account.balance,
        );

        if (totalAssets == 0) {
          return const SizedBox.shrink();
        }

        // If same currency, no need to show conversion
        if (baseCurrency == displayCurrency) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<ExchangeRateInfo>(
          future: exchangeRateService.getRateInfo(baseCurrency, displayCurrency),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Converting currency...',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            final fxInfo = snapshot.data!;
            final baseAmount =
                CurrencyFormatter.format(totalAssets, baseCurrency);
            final convertedAmount = fxInfo.isFallback
                ? baseAmount
                : CurrencyFormatter.format(
                    totalAssets * fxInfo.rate,
                    displayCurrency,
                  );
            final isWarning = fxInfo.isStale || fxInfo.isFallback;
            final statusText = fxInfo.isFallback
                ? 'Live FX unavailable. Showing base-currency value.'
                : fxInfo.isStale
                    ? 'Using stale cached exchange rate.'
                    : 'Exchange rates update every 24 hours';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isWarning
                      ? Theme.of(context).colorScheme.error.withValues(alpha: 0.45)
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                        size: 16,
                        color: isWarning
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Currency Conversion Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isWarning
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Total Assets:',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$baseAmount ($baseCurrency)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        fxInfo.isFallback ? Icons.block : Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fxInfo.isFallback
                            ? '$convertedAmount ($baseCurrency)'
                            : '$convertedAmount ($displayCurrency)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isWarning
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: isWarning
                          ? Theme.of(context).colorScheme.error
                          : Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


