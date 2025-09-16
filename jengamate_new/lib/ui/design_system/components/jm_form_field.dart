import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum JMFormFieldVariant { outlined, filled, underlined }
enum JMFormFieldSize { small, medium, large }

class JMFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final JMFormFieldVariant variant;
  final JMFormFieldSize size;
  final String? helperText;
  final String? errorText;
  final bool showCounter;
  final int? maxLength;

  const JMFormField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.variant = JMFormFieldVariant.outlined,
    this.size = JMFormFieldSize.medium,
    this.helperText,
    this.errorText,
    this.showCounter = false,
    this.maxLength,
  });

  @override
  State<JMFormField> createState() => _JMFormFieldState();
}

class _JMFormFieldState extends State<JMFormField> with TickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));

    _isObscured = widget.obscureText;
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  InputDecoration _getDecoration(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(12);

    InputBorder getBorder(Color color, {double width = 1.0}) {
      switch (widget.variant) {
        case JMFormFieldVariant.outlined:
          return OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: color, width: width),
          );
        case JMFormFieldVariant.filled:
          return UnderlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: color, width: width),
          );
        case JMFormFieldVariant.underlined:
          return UnderlineInputBorder(
            borderSide: BorderSide(color: color, width: width),
          );
      }
    }

    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      helperText: widget.helperText,
      errorText: widget.errorText,
      counterText: widget.showCounter ? null : '',
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.obscureText
          ? IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
            )
          : widget.suffixIcon,
      filled: widget.variant == JMFormFieldVariant.filled,
      fillColor: widget.variant == JMFormFieldVariant.filled
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      contentPadding: _getContentPadding(),
      border: getBorder(colorScheme.outline),
      enabledBorder: getBorder(colorScheme.outline),
      focusedBorder: getBorder(colorScheme.primary, width: 2.0),
      errorBorder: getBorder(colorScheme.error),
      focusedErrorBorder: getBorder(colorScheme.error, width: 2.0),
      labelStyle: TextStyle(
        color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontSize: _getFontSize(),
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: _getFontSize(),
      ),
    );
  }

  EdgeInsets _getContentPadding() {
    double horizontal = 16.0;
    double vertical = 12.0;

    switch (widget.size) {
      case JMFormFieldSize.small:
        horizontal = 12.0;
        vertical = 8.0;
        break;
      case JMFormFieldSize.medium:
        horizontal = 16.0;
        vertical = 12.0;
        break;
      case JMFormFieldSize.large:
        horizontal = 20.0;
        vertical = 16.0;
        break;
    }

    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  double _getFontSize() {
    switch (widget.size) {
      case JMFormFieldSize.small:
        return 12.0;
      case JMFormFieldSize.medium:
        return 14.0;
      case JMFormFieldSize.large:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onFocusChange: _handleFocusChange,
      child: AnimatedBuilder(
        animation: _focusAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_focusAnimation.value * 0.01),
            child: child,
          );
        },
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          obscureText: widget.obscureText && _isObscured,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          enabled: widget.enabled,
          initialValue: widget.initialValue,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          style: TextStyle(
            fontSize: _getFontSize(),
            color: widget.enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          decoration: _getDecoration(theme),
        ),
      ),
    );
  }
}
