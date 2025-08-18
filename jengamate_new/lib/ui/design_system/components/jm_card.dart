import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

class JMCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  const JMCard({super.key, required this.child, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.all(JMSpacing.md),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(JMSpacing.lg),
        child: child,
      ),
    );
  }
}
