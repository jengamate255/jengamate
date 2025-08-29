import 'package:flutter/material.dart';
import 'package:jengamate/utils/responsive.dart';

class MobileOptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const MobileOptimizedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? Responsive.getResponsivePadding(context);
    final responsiveMargin = margin ?? Responsive.getResponsiveMargin(context);
    final responsiveElevation = elevation ?? Responsive.getResponsiveElevation(context);
    final responsiveBorderRadius = borderRadius ?? 
        BorderRadius.circular(Responsive.getResponsiveBorderRadius(context));

    Widget cardWidget = Card(
      elevation: responsiveElevation,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: responsiveBorderRadius),
      margin: responsiveMargin,
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: responsiveBorderRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class MobileOptimizedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final bool isLoading;
  final double? width;

  const MobileOptimizedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = Responsive.getResponsiveButtonHeight(context);
    final fontSize = Responsive.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18);

    Widget buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? (isOutlined ? Theme.of(context).primaryColor : Colors.white),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: Responsive.getResponsiveIconSize(context)),
                SizedBox(width: Responsive.getResponsiveSpacing(context)),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    Widget button = SizedBox(
      height: buttonHeight,
      width: width,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: foregroundColor ?? Theme.of(context).primaryColor,
                side: BorderSide(
                  color: backgroundColor ?? Theme.of(context).primaryColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.getResponsiveBorderRadius(context),
                  ),
                ),
              ),
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
                foregroundColor: foregroundColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.getResponsiveBorderRadius(context),
                  ),
                ),
              ),
              child: buttonChild,
            ),
    );

    return button;
  }
}

class MobileOptimizedTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;

  const MobileOptimizedTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final inputHeight = Responsive.getResponsiveInputHeight(context);
    final fontSize = Responsive.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18);
    final borderRadius = Responsive.getResponsiveBorderRadius(context);

    return SizedBox(
      height: maxLines == 1 ? inputHeight : null,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Responsive.getResponsiveSpacing(context),
            vertical: Responsive.getResponsiveSpacing(context),
          ),
        ),
      ),
    );
  }
}

class MobileOptimizedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;

  const MobileOptimizedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final tileHeight = Responsive.getResponsiveListTileHeight(context);
    final padding = contentPadding ?? Responsive.getResponsivePadding(context);

    return SizedBox(
      height: tileHeight,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: padding,
        dense: Responsive.isMobile(context),
      ),
    );
  }
}

class MobileOptimizedChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? labelColor;
  final VoidCallback? onTap;
  final bool selected;

  const MobileOptimizedChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.labelColor,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipHeight = Responsive.getResponsiveChipHeight(context);
    final fontSize = Responsive.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16);

    return SizedBox(
      height: chipHeight,
      child: onTap != null
          ? FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: labelColor,
                ),
              ),
              selected: selected,
              onSelected: (_) => onTap?.call(),
              backgroundColor: backgroundColor,
              selectedColor: backgroundColor?.withValues(alpha: 0.3) ??
                  Theme.of(context).primaryColor.withValues(alpha: 0.3),
            )
          : Chip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: labelColor,
                ),
              ),
              backgroundColor: backgroundColor,
            ),
    );
  }
}

class MobileOptimizedDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const MobileOptimizedDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final dialogWidth = Responsive.getResponsiveDialogWidth(context);
    final padding = Responsive.getResponsivePadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.getResponsiveBorderRadius(context),
        ),
      ),
      child: Container(
        width: dialogWidth,
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                ),
              ),
              SizedBox(height: Responsive.getResponsiveSpacing(context)),
            ],
            content,
            if (actions != null && actions!.isNotEmpty) ...[
              SizedBox(height: Responsive.getResponsiveSpacing(context) * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!
                    .map((action) => Padding(
                          padding: EdgeInsets.only(
                            left: Responsive.getResponsiveSpacing(context),
                          ),
                          child: action,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
