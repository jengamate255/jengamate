import 'package:flutter/material.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Responsive layout utilities
class ResponsiveLayout {
  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.tablet;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tablet;
  }

  /// Check if screen is large desktop size
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.largeDesktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < ResponsiveBreakpoints.mobile) {
      return const EdgeInsets.all(JMSpacing.sm);
    } else if (width < ResponsiveBreakpoints.tablet) {
      return const EdgeInsets.all(JMSpacing.md);
    } else if (width < ResponsiveBreakpoints.desktop) {
      return const EdgeInsets.all(JMSpacing.lg);
    } else {
      return const EdgeInsets.all(JMSpacing.xl);
    }
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < ResponsiveBreakpoints.mobile) {
      return JMSpacing.sm;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return JMSpacing.md;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return JMSpacing.lg;
    } else {
      return JMSpacing.xl;
    }
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3, int largeDesktop = 4}) {
    if (isLargeDesktop(context)) return largeDesktop;
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Get responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return 1200;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return 1000;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return 800;
    } else {
      return width - 32; // Full width minus padding
    }
  }
}

/// Responsive wrapper widget that adapts layout based on screen size
class ResponsiveWrapper extends StatelessWidget {
  final Widget? child;
  final Widget? mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;
  final Widget? largeDesktopLayout;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveWrapper({
    super.key,
    this.child = null,
    this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
    this.largeDesktopLayout,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget selectedLayout;
        
        if (constraints.maxWidth >= ResponsiveBreakpoints.largeDesktop &&
            largeDesktopLayout != null) {
          selectedLayout = largeDesktopLayout!;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.desktop &&
            desktopLayout != null) {
          selectedLayout = desktopLayout!;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet &&
            tabletLayout != null) {
          selectedLayout = tabletLayout!;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.mobile &&
            mobileLayout != null) {
          selectedLayout = mobileLayout!;
        } else if (child != null) {
          selectedLayout = child!;
        } else {
          // If no specific layout is provided and there's no default child, throw an error.
          throw FlutterError(
              'ResponsiveWrapper requires at least one layout (e.g., child, mobileLayout, etc.) to be provided.');
        }

        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? ResponsiveLayout.getMaxContentWidth(context),
            ),
            padding: padding ?? ResponsiveLayout.getResponsivePadding(context),
            child: selectedLayout,
          ),
        );
      },
    );
  }
}

/// Adaptive padding widget that adjusts based on screen size
class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? largeDesktopPadding;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.largeDesktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _getResponsivePadding(context),
      child: child,
    );
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= ResponsiveBreakpoints.largeDesktop && largeDesktopPadding != null) {
      return largeDesktopPadding!;
    } else if (width >= ResponsiveBreakpoints.desktop && desktopPadding != null) {
      return desktopPadding!;
    } else if (width >= ResponsiveBreakpoints.tablet && tabletPadding != null) {
      return tabletPadding!;
    } else if (width >= ResponsiveBreakpoints.mobile && mobilePadding != null) {
      return mobilePadding!;
    } else {
      return ResponsiveLayout.getResponsivePadding(context);
    }
  }
}

/// Responsive navigation widget that shows bottom nav on mobile and sidebar on desktop
class ResponsiveNavigation extends StatelessWidget {
  final int currentIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget? leading;
  final Widget? trailing;

  const ResponsiveNavigation({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      mobileLayout: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
      tabletLayout: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map((dest) => NavigationRailDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon,
                  label: Text(dest.label),
                ))
            .toList(),
        leading: leading,
        trailing: trailing,
        extended: false,
      ),
      desktopLayout: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map((dest) => NavigationRailDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon,
                  label: Text(dest.label),
                ))
            .toList(),
        leading: leading,
        trailing: trailing,
        extended: true,
      ),
    );
  }
}

/// Responsive scaffold that adapts layout for different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ResponsiveLayout.isDesktop(context);
        
        return Scaffold(
          appBar: appBar,
          body: Row(
            children: [
              if (isDesktop && drawer != null)
                SizedBox(
                  width: 250,
                  child: drawer,
                ),
              Expanded(
                child: ResponsiveWrapper(
                  child: body,
                ),
              ),
            ],
          ),
          bottomNavigationBar: bottomNavigationBar,
          drawer: !isDesktop ? drawer : null,
          endDrawer: endDrawer,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}
