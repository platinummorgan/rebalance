import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple ephemeral privacy mode (mask balances) without persisting to storage.
final privacyModeProvider = StateProvider<bool>((ref) => false);

/// Helper extension to mask monetary values when privacy mode enabled.
extension PrivacyMasking on num {
  String masked(WidgetRef ref) {
    final enabled = ref.read(privacyModeProvider);
    if (!enabled) return toStringAsFixed(0);
    return '•••';
  }
}
