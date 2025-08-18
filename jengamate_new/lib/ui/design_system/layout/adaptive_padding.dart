import 'package:flutter/widgets.dart';
import '../tokens/spacing.dart';
import 'breakpoints.dart';

class AdaptivePadding extends StatelessWidget {
  final Widget child;
  const AdaptivePadding({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final inset = JMBreakpoints.isDesktop(context)
        ? JMSpacing.xl
        : JMBreakpoints.isTablet(context)
            ? JMSpacing.lg
            : JMSpacing.md;
    return Padding(padding: EdgeInsets.all(inset), child: child);
  }
}
