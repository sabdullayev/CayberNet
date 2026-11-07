import 'package:flutter/material.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

enum CyberCardCutStyle {
  /// Cut top-left and bottom-right corners (Classic Arasaka / Tactical HUD)
  tacticalOpposite,
  /// Cut all 4 corners symmetrically
  allCorners,
}

class CyberCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final double cutRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final String? hudTag;
  final CyberCardCutStyle cutStyle;
  final Widget? headerLeading;

  const CyberCard({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.cutRadius = 10,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderWidth = 1.0,
    this.shadows,
    this.hudTag,
    this.cutStyle = CyberCardCutStyle.tacticalOpposite,
    this.headerLeading,
  });

  BorderRadius get _effectiveRadius {
    switch (cutStyle) {
      case CyberCardCutStyle.tacticalOpposite:
        return BorderRadius.only(
          topLeft: Radius.circular(cutRadius),
          bottomRight: Radius.circular(cutRadius),
          topRight: const Radius.circular(2),
          bottomLeft: const Radius.circular(2),
        );
      case CyberCardCutStyle.allCorners:
        return BorderRadius.all(Radius.circular(cutRadius));
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? CyberColors.cyberCyan.withValues(alpha: 0.35);
    final effectiveBg = backgroundColor ?? CyberColors.surface.withValues(alpha: 0.85);
    final shape = BeveledRectangleBorder(
      borderRadius: _effectiveRadius,
      side: BorderSide(
        color: effectiveBorderColor,
        width: borderWidth,
      ),
    );

    return Container(
      margin: margin,
      decoration: ShapeDecoration(
        color: effectiveBg,
        shape: shape,
        shadows: shadows ??
            [
              BoxShadow(
                color: effectiveBorderColor.withValues(alpha: 0.18),
                blurRadius: 12,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hudTag != null || headerLeading != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: effectiveBorderColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (headerLeading != null)
                      headerLeading!
                    else
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: effectiveBorderColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SYS.PANEL',
                            style: CyberTypography.monoSmall.copyWith(
                              fontSize: 9,
                              letterSpacing: 1.5,
                              color: CyberColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    if (hudTag != null)
                      Text(
                        '[ $hudTag ]',
                        style: CyberTypography.monoSmall.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: effectiveBorderColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
