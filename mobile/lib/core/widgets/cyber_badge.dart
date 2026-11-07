import 'package:flutter/material.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

class CyberBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double cutRadius;
  final bool isFilled;

  const CyberBadge({
    super.key,
    required this.label,
    this.color = CyberColors.cyberCyan,
    this.icon,
    this.cutRadius = 4,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: isFilled ? color.withValues(alpha: 0.2) : CyberColors.surface,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cutRadius)),
          side: BorderSide(
            color: color,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: CyberTypography.monoSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
