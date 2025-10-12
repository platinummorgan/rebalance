import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/premium_helper.dart';

class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                      spacing: 12,
                      runSpacing: 12,
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
                              : _updateColorTheme(ref, theme),
                          child: Container(
                            width: 80,
                            height: 80,
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
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppTheme.getColorThemeName(theme),
                                      style: TextStyle(
                                        color: isLocked
                                            ? Colors.white54
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isLocked)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: PremiumHelper.premiumBadge(
                                      context,
                                      size: 16,
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

            // Dark Mode Toggle
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme instead of light'),
                value: settings.darkModeEnabled,
                onChanged: (value) => _updateDarkMode(ref, value),
              ),
            ),

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
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Import & Export'),
                    subtitle: const Text('Backup and restore your data'),
                    onTap: () => context.push('/export'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('Pro Features'),
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
                      'https://platinummorgan.github.io/rebalance/terms.html',
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
            child: const Text('Cancel'),
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

  void _updateColorTheme(WidgetRef ref, ColorTheme theme) {
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
      );
      settingsNotifier.updateSettings(updatedSettings);
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
        homeCountry: currentSettings.homeCountry,
        globalDiversificationMode: mode,
        intlTolerancePct: currentSettings.intlTolerancePct,
        intlFloorPct: currentSettings.intlFloorPct,
        intlPenaltyScale: currentSettings.intlPenaltyScale,
        intlTargetOverride: currentSettings.intlTargetOverride,
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
