import 'package:flutter/material.dart';

/// Design system color tokens and schemes
class JMColors {
  // Brand seed color (adjust if brand changes)
  static const Color seed = Color(0xFF2E7D32); // green 800-ish

  // Light/Dark color schemes derived from seed
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
}
