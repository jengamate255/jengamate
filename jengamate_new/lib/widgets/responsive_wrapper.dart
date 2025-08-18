import 'package:flutter/material.dart';
import 'package:jengamate/utils/responsive.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (Responsive.isDesktop(context)) {
        return child;
      } else if (Responsive.isTablet(context)) {
        return child; // Or a tablet-specific layout
      } else {
        return child; // Default to mobile layout
      }
    });
  }
}

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: Responsive.isMobile(context) ? drawer : null,
      endDrawer: Responsive.isDesktop(context) ? drawer : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? Responsive.getResponsiveCardWidth(context),
      height: height,
      padding: padding ?? Responsive.getResponsivePadding(context),
      margin: margin ?? Responsive.getResponsiveMargin(context),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveBorderRadius(context),
        ),
      ),
      child: child,
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.elevation,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? Responsive.getResponsiveElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveBorderRadius(context),
        ),
      ),
      margin: margin ?? Responsive.getResponsiveMargin(context),
      child: Padding(
        padding: padding ?? Responsive.getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            crossAxisCount ?? Responsive.getResponsiveGridCount(context),
        childAspectRatio:
            childAspectRatio ?? Responsive.getResponsiveAspectRatio(context),
        crossAxisSpacing:
            crossAxisSpacing ?? Responsive.getResponsiveSpacing(context),
        mainAxisSpacing:
            mainAxisSpacing ?? Responsive.getResponsiveSpacing(context),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding ?? Responsive.getResponsivePadding(context),
      children: children
          .expand((widget) => [
                widget,
                SizedBox(height: Responsive.getResponsiveSpacing(context)),
              ])
          .toList()
        ..removeLast(), // Remove the last SizedBox
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double? height;
  final Color? color;

  const ResponsiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.getResponsiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveBorderRadius(context),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class ResponsiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;

  const ResponsiveTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.getResponsiveInputHeight(context),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.getResponsiveBorderRadius(context),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Responsive.getResponsiveSpacing(context),
            vertical: Responsive.getResponsiveSpacing(context) / 2,
          ),
        ),
      ),
    );
  }
}
