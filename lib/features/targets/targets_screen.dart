import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../app.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/premium_helper.dart';
import '../../utils/currency_formatter.dart';
import '../../services/exchange_rate_service.dart';
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
                        const Text(
                          'Color Theme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose your preferred color scheme',
                      style: TextStyle(color: Colors.grey),
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
                                      AppTheme.getColorThemeName(theme),
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
                        const Text(
                          'Currency',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Display amounts in your preferred currency',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
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
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your preferred language',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: settings.language ?? 'en',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'en',
                          child: Row(
                            children: [
                              Text('🇺🇸', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Text('English'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'hi',
                          child: Row(
                            children: [
                              Text('🇮🇳', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Text('हिन्दी (Hindi)'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'bn',
                          child: Row(
                            children: [
                              Text('🇧🇩', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Text('বাংলা (Bengali)'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'ar',
                          child: Row(
                            children: [
                              Text('🇸🇩', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Text('العربية (Arabic)'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'fa',
                          child: Row(
                            children: [
                              Text('🇮🇷', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 12),
                              Text('فارسی (Persian)'),
                            ],
                          ),
                        ),
                        const DropdownMenuItem(
                          value: 'request',
                          child: Row(
                            children: [
                              Icon(Icons.email, size: 20),
                              SizedBox(width: 12),
                              Text('Request a language...'),
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
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: Text(AppLocalizations.of(context)!.darkMode),
                subtitle: const Text('Use dark theme instead of light'),
                value: settings.darkModeEnabled,
                onChanged: (value) => _updateDarkMode(ref, value),
              ),
            ),

            // Debug Pro Toggle (only visible in debug mode)
            if (const bool.fromEnvironment('dart.vm.product') == false) ...[
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
                      const Text('Pro Status'),
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
                        ? 'Testing as Pro user'
                        : 'Testing as Free user',
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
                  const ListTile(
                    leading: Icon(Icons.public),
                    title: Text('International Exposure'),
                    subtitle: Text(
                      'Control how international exposure affects your score',
                    ),
                    onTap: null,
                  ),
                  RadioListTile<String>(
                    value: 'standard',
                    groupValue: settings.globalDiversificationMode,
                    title: const Text('Standard'),
                    subtitle:
                        const Text('Default policy: penalize large deviations'),
                    onChanged: (v) =>
                        _updateDiversificationMode(ref, v ?? 'standard'),
                  ),
                  RadioListTile<String>(
                    value: 'light',
                    groupValue: settings.globalDiversificationMode,
                    title: const Text('Light'),
                    subtitle: const Text(
                      'Less punitive: small deviations are tolerated',
                    ),
                    onChanged: (v) =>
                        _updateDiversificationMode(ref, v ?? 'light'),
                  ),
                  RadioListTile<String>(
                    value: 'off',
                    groupValue: settings.globalDiversificationMode,
                    title: const Text('Off (Mute)'),
                    subtitle: const Text(
                      'Exclude International Exposure from your score',
                    ),
                    onChanged: (v) =>
                        _updateDiversificationMode(ref, v ?? 'off'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Targets & Alerts'),
                    subtitle: const Text(
                      'Set allocation targets and drift thresholds',
                    ),
                    onTap: () => context.push('/targets/detail'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_upload),
                    title: const Text('Import CSV'),
                    subtitle: const Text('Import accounts, debts, or income'),
                    onTap: () => context.push('/import/csv'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Import & Export'),
                    subtitle: const Text('Backup and restore your data'),
                    onTap: () => context.push('/export'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: Text(AppLocalizations.of(context)!.proFeatures),
                    subtitle: const Text('Unlock advanced features'),
                    onTap: () => context.push('/pro'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: const Text('App info and disclaimers'),
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
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('How we protect your data'),
                    trailing: const Icon(Icons.open_in_new, size: 20),
                    onTap: () => _launchURL(
                      'https://platinummorgan.github.io/rebalance/privacy.html',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms of Service'),
                    subtitle: const Text('Legal terms and conditions'),
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
                title: const Text('Send Feedback'),
                subtitle: const Text('Share your thoughts and suggestions'),
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
                              'Exit App',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Close the application',
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
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
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
            child: const Text('Exit'),
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
      feature: '${AppTheme.getColorThemeName(theme)} Theme',
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
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'Support@platovalabs.com',
      query:
          'subject=Language Support Request&body=I would like to request support for the following language:%0D%0A%0D%0ALanguage: %0D%0ARegion: %0D%0A%0D%0AThank you!',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email. Please email Support@platovalabs.com',
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

        return FutureBuilder<String>(
          future: CurrencyFormatter.formatWithConversion(
            totalAssets,
            baseCurrency,
            displayCurrency,
            exchangeRateService,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
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

            final convertedAmount = snapshot.data!;
            final baseAmount =
                CurrencyFormatter.format(totalAssets, baseCurrency);

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Currency Conversion Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
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
                        Icons.arrow_forward,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$convertedAmount ($displayCurrency)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Exchange rates update every 24 hours',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
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
