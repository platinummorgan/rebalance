// Temporary script to reset Pro status to false
// Run with: dart run reset_pro_status.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'lib/data/models.dart';

Future<void> main() async {
  print('🔧 Resetting Pro status...');

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters (needed to read Settings)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(RiskBandAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(ColorThemeAdapter());
  }

  // Open settings box (unencrypted for this script)
  final settingsBox = await Hive.openBox<Settings>('settings');

  // Get current settings
  final settings = settingsBox.get('main');

  if (settings == null) {
    print('❌ No settings found');
    await Hive.close();
    return;
  }

  print('Current Pro status: ${settings.isPro}');

  // Set isPro to false
  settings.isPro = false;

  // Save back
  await settingsBox.put('main', settings);

  print('✅ Pro status reset to: ${settings.isPro}');
  print('🎉 Done! Restart your app.');

  await Hive.close();
}
