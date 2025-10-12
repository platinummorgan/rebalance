// BACKUP OF PRO MEMBERSHIP TOGGLE FOR DEVELOPMENT
// This code was removed from lib/routes.dart for the release version
// To restore for development: Copy the sections below back into the About screen

// ============================================================================
// SECTION 1: UI Code (goes in the About screen body, after the Disclaimer)
// ============================================================================

/*
              // Developer/Testing Section
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Developer Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Pro Status Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            settings.isPro
                                ? Icons.workspace_premium
                                : Icons.star_outline,
                            color: settings.isPro
                                ? Colors.amber
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pro Membership Status',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  settings.isPro
                                      ? 'You have Pro access with all premium features unlocked'
                                      : 'Enable Pro access to test premium features',
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
                          Switch(
                            value: settings.isPro,
                            onChanged: (value) =>
                                _toggleProStatus(ref, settings, value),
                          ),
                        ],
                      ),
                      if (settings.isPro) ...[
                        const SizedBox(height: 12),
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
                                Icons.star,
                                color: Colors.amber.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pro features unlocked: Advanced planning, unlimited accounts, premium insights',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Note: This is a testing toggle for development purposes only.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
*/

// ============================================================================
// SECTION 2: Helper Function (goes at the bottom of the _AboutScreenState class)
// ============================================================================

/*
  Future<void> _toggleProStatus(
    WidgetRef ref,
    Settings currentSettings,
    bool isPro,
  ) async {
    try {
      final updatedSettings = Settings(
        riskBand: currentSettings.riskBand,
        monthlyEssentials: currentSettings.monthlyEssentials,
        driftThresholdPct: currentSettings.driftThresholdPct,
        notificationsEnabled: currentSettings.notificationsEnabled,
        usEquityTargetPct: currentSettings.usEquityTargetPct,
        isPro: isPro, // Toggle the Pro status
        biometricLockEnabled: currentSettings.biometricLockEnabled,
        darkModeEnabled: currentSettings.darkModeEnabled,
        colorTheme: currentSettings.colorTheme,
      );

      await ref.read(settingsProvider.notifier).updateSettings(updatedSettings);

      // Show confirmation
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text(
              isPro
                  ? '🌟 Pro features enabled! You can now test premium functionality.'
                  : 'Pro features disabled. You\'re now in free tier mode.',
            ),
            backgroundColor: isPro ? Colors.amber.shade600 : null,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Failed to update Pro status: $e'),
            backgroundColor: Theme.of(ref.context).colorScheme.error,
          ),
        );
      }
    }
  }
*/
