import 'package:flutter/material.dart';

class JMTypography {
  static const TextStyle heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle body = TextStyle(fontSize: 14);
  static const TextStyle bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

  static TextTheme textTheme(ColorScheme scheme) {
    final base = Typography.material2021(platform: TargetPlatform.android).black;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
