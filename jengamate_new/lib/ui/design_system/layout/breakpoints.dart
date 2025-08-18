import 'package:flutter/widgets.dart';

class JMBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobile && w < tablet;
  }
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tablet;
}
