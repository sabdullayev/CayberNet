import 'package:flutter/material.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

class CyberTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Color accentColor;
  final int maxLines;
  final bool enabled;
  final double cutRadius;
  final String? hudTag;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const CyberTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.accentColor = CyberColors.cyberCyan,
    this.maxLines = 1,
    this.enabled = true,
    this.cutRadius = 6,
    this.hudTag,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<CyberTextField> createState() => _CyberTextFieldState();
}

class _CyberTextFieldState extends State<CyberTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveAccent = widget.accentColor;
    final Color borderColor = _isFocused
        ? effectiveAccent
        : CyberColors.borderSubtle;

    final shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(widget.cutRadius),
        bottomRight: Radius.circular(widget.cutRadius),
        topRight: const Radius.circular(2),
        bottomLeft: const Radius.circular(2),
      ),
      side: BorderSide(
        color: borderColor,
        width: 1.0,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.labelText!.toUpperCase(),
              style: CyberTypography.monoSmall.copyWith(
                color: _isFocused ? effectiveAccent : CyberColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: ShapeDecoration(
            color: CyberColors.inputFill,
            shape: shape,
            shadows: _isFocused
                ? [
                    BoxShadow(
                      color: effectiveAccent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // 3px Glowing Accent Bar on Left Border
              Positioned(
                left: 0,
                top: 4,
                bottom: 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  decoration: BoxDecoration(
                    color: _isFocused ? effectiveAccent : effectiveAccent.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: effectiveAccent,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  onChanged: widget.onChanged,
                  validator: widget.validator,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  style: CyberTypography.monoRegular.copyWith(
                    color: CyberColors.textPrimary,
                    fontSize: 13,
                  ),
                  cursorColor: effectiveAccent,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: CyberTypography.monoRegular.copyWith(
                      color: CyberColors.textMuted,
                      fontSize: 12,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _isFocused
                                ? effectiveAccent
                                : CyberColors.textMuted,
                            size: 18,
                          )
                        : null,
                    suffixIcon: widget.suffixIcon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
