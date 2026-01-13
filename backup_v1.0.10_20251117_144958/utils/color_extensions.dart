import 'package:flutter/material.dart';

/// Small helper extension to allow color component access and convenient
/// modifications using fractional RGB/alpha values in the range 0.0 - 1.0.
///
/// The codebase calls `color.r`, `color.g`, `color.b` and `color.withValues(...)`
/// in many places; this extension provides those helpers.
extension ColorValues on Color {
  /// Red component as a 0.0-1.0 double
  double get r => red / 255.0;

  /// Green component as a 0.0-1.0 double
  double get g => green / 255.0;

  /// Blue component as a 0.0-1.0 double
  double get b => blue / 255.0;

  /// Return a new [Color] with the provided component overrides.
  /// All values are fractional (0.0 - 1.0). If a component is null the
  /// original component is preserved.
  Color withValues({
    double? red,
    double? green,
    double? blue,
    double? alpha,
  }) {
    final rr = ((red ?? this.r) * 255).round().clamp(0, 255);
    final gg = ((green ?? this.g) * 255).round().clamp(0, 255);
    final bb = ((blue ?? this.b) * 255).round().clamp(0, 255);
    final aa = ((alpha ?? opacity) * 255).round().clamp(0, 255);
    return Color.fromARGB(aa, rr, gg, bb);
  }
}
