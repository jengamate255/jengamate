import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints for different device types
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get current screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get current screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < mobileBreakpoint;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenWidth(context) >= mobileBreakpoint &&
        getScreenWidth(context) < tabletBreakpoint;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= tabletBreakpoint;
  }

  // Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Get responsive margin based on device type
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);
    }
  }

  // Get responsive font size based on device type
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive icon size based on device type
  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 20.0,
    double tablet = 24.0,
    double desktop = 28.0,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive card width based on device type
  static double getResponsiveCardWidth(BuildContext context) {
    double screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth - 32; // Full width minus padding
    } else if (isTablet(context)) {
      return (screenWidth - 48) / 2; // Half width for tablets
    } else {
      return (screenWidth - 64) / 3; // One-third width for desktop
    }
  }

  // Get responsive grid cross axis count
  static int getResponsiveGridCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Get responsive aspect ratio for cards
  static double getResponsiveAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 1.2; // Taller cards on mobile
    } else if (isTablet(context)) {
      return 1.0; // Square cards on tablet
    } else {
      return 0.8; // Wider cards on desktop
    }
  }

  // Get responsive spacing between elements
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  // Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  // Get responsive input field height
  static double getResponsiveInputHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48.0;
    } else if (isTablet(context)) {
      return 56.0;
    } else {
      return 64.0;
    }
  }

  // Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else if (isTablet(context)) {
      return kToolbarHeight + 8;
    } else {
      return kToolbarHeight + 16;
    }
  }

  // Get responsive bottom navigation height
  static double getResponsiveBottomNavHeight(BuildContext context) {
    if (isMobile(context)) {
      return kBottomNavigationBarHeight;
    } else if (isTablet(context)) {
      return kBottomNavigationBarHeight + 8;
    } else {
      return kBottomNavigationBarHeight + 16;
    }
  }

  // Get responsive drawer width
  static double getResponsiveDrawerWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) * 0.8;
    } else if (isTablet(context)) {
      return 280.0;
    } else {
      return 320.0;
    }
  }

  // Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) - 32;
    } else if (isTablet(context)) {
      return 500.0;
    } else {
      return 600.0;
    }
  }

  // Get responsive list tile height
  static double getResponsiveListTileHeight(BuildContext context) {
    if (isMobile(context)) {
      return 72.0;
    } else if (isTablet(context)) {
      return 80.0;
    } else {
      return 88.0;
    }
  }

  // Get responsive image size
  static double getResponsiveImageSize(BuildContext context) {
    if (isMobile(context)) {
      return 80.0;
    } else if (isTablet(context)) {
      return 100.0;
    } else {
      return 120.0;
    }
  }

  // Get responsive avatar size
  static double getResponsiveAvatarSize(BuildContext context) {
    if (isMobile(context)) {
      return 40.0;
    } else if (isTablet(context)) {
      return 48.0;
    } else {
      return 56.0;
    }
  }

  // Get responsive chip height
  static double getResponsiveChipHeight(BuildContext context) {
    if (isMobile(context)) {
      return 32.0;
    } else if (isTablet(context)) {
      return 36.0;
    } else {
      return 40.0;
    }
  }

  // Get responsive divider height
  static double getResponsiveDividerHeight(BuildContext context) {
    if (isMobile(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.5;
    } else {
      return 2.0;
    }
  }

  // Get responsive elevation
  static double getResponsiveElevation(BuildContext context) {
    if (isMobile(context)) {
      return 2.0;
    } else if (isTablet(context)) {
      return 3.0;
    } else {
      return 4.0;
    }
  }

  // Get responsive animation duration
  static Duration getResponsiveAnimationDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(milliseconds: 200);
    } else if (isTablet(context)) {
      return const Duration(milliseconds: 250);
    } else {
      return const Duration(milliseconds: 300);
    }
  }
}
