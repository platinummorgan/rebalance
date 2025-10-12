import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../routes.dart' show AppRouter;

class PremiumHelper {
  /// Check if user has Pro access
  static bool isPro(WidgetRef ref) {
    final settings = ref.read(settingsProvider).valueOrNull;
    return settings?.isPro ?? false;
  }

  /// Show upgrade dialog for premium features
  static void showUpgradeDialog(
    BuildContext context, {
    required String feature,
    String? description,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.workspace_premium,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        title: Text('$feature is Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              description ??
                  '$feature requires Rebalance Pro to access advanced financial planning tools.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '\$9.99 lifetime • \$1.49/month',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRouter.pro);
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  /// Show upgrade bottom sheet for more detailed premium info
  static void showUpgradeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Pro badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium,
                        color: Colors.white, size: 20,),
                    SizedBox(width: 8),
                    Text(
                      'Rebalance Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock Advanced Financial Planning',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Features list
              ..._buildFeatureList(context),

              const SizedBox(height: 32),

              // Pricing buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRouter.pro);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Column(
                        children: [
                          Text('\$1.49',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,),),
                          Text('per month', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRouter.pro);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('\$9.99',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,),),
                              SizedBox(width: 4),
                              Icon(Icons.star, size: 16),
                            ],
                          ),
                          Text('lifetime', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _buildFeatureList(BuildContext context) {
    final features = [
      {
        'icon': Icons.palette,
        'title': 'All Color Themes',
        'desc': 'Blue, red, purple, etc.',
      },
      {
        'icon': Icons.dark_mode,
        'title': 'Dark Mode',
        'desc': 'Easy on the eyes',
      },
      {
        'icon': Icons.picture_as_pdf,
        'title': 'PDF Export',
        'desc': 'Professional reports',
      },
      {
        'icon': Icons.notifications,
        'title': 'Smart Alerts',
        'desc': 'Rebalancing reminders',
      },
      {
        'icon': Icons.cloud_upload,
        'title': 'Cloud Backup',
        'desc': 'Never lose your data',
      },
      {
        'icon': Icons.fingerprint,
        'title': 'Biometric Lock',
        'desc': 'Secure your finances',
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Charts',
        'desc': 'Detailed breakdowns',
      },
      {
        'icon': Icons.history,
        'title': 'Historical Tracking',
        'desc': 'See your progress over time',
      },
    ];

    return features
        .map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          feature['desc'] as String,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),)
        .toList();
  }

  /// Widget to show premium badge next to features
  static Widget premiumBadge(BuildContext context, {double size = 16}) {
    return Container(
      padding: EdgeInsets.all(size * 0.25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Icon(
        Icons.workspace_premium,
        color: Colors.white,
        size: size,
      ),
    );
  }

  /// Check if a feature should be locked for free users
  static bool isFeatureLocked(WidgetRef ref, String feature) {
    if (isPro(ref)) return false;

    // Define which features are premium
    const premiumFeatures = {
      'dark_mode',
      'color_themes_advanced', // Only basic green/blue for free
      'pdf_export',
      'notifications',
      'cloud_backup',
      'biometric_lock',
      'advanced_charts',
      'historical_tracking',
      'custom_targets',
    };

    return premiumFeatures.contains(feature);
  }
}

/// Extension to easily check pro status in widgets
extension PremiumContext on BuildContext {
  void showUpgradeDialog(String feature, {String? description}) {
    PremiumHelper.showUpgradeDialog(this,
        feature: feature, description: description,);
  }

  void showUpgradeBottomSheet() {
    PremiumHelper.showUpgradeBottomSheet(this);
  }
}
