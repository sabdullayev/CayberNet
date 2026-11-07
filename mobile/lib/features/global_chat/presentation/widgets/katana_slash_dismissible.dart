import 'package:flutter/material.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../../core/theme/cyber_typography.dart';

class KatanaSlashDismissible extends StatelessWidget {
  final Widget child;
  final String messageId;
  final VoidCallback onSlash;

  const KatanaSlashDismissible({
    super.key,
    required this.child,
    required this.messageId,
    required this.onSlash,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('slash_$messageId'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onSlash();
        return true;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: CyberColors.neonCrimson.withValues(alpha: 0.25),
          border: Border.all(color: CyberColors.neonCrimson, width: 1.5),
        ),
        child: CustomPaint(
          size: const Size(200, 60),
          painter: _KatanaBladeSlashPainter(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'КИБЕР-УДАР / PURGE',
                style: CyberTypography.monoBold.copyWith(
                  color: CyberColors.neonCrimson,
                  letterSpacing: 2.0,
                  fontSize: 13,
                  shadows: [
                    const Shadow(
                      color: CyberColors.neonCrimson,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.flash_on,
                color: CyberColors.neonCrimson,
                size: 26,
              ),
            ],
          ),
        ),
      ),
      child: child,
    );
  }
}

class _KatanaBladeSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final slashPaint = Paint()
      ..color = CyberColors.neonCrimson
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final whiteGlow = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Diagonal slashing cut line
    final p1 = Offset(size.width * 0.1, size.height * 0.9);
    final p2 = Offset(size.width * 0.95, size.height * 0.1);

    canvas.drawLine(p1, p2, slashPaint);
    canvas.drawLine(p1, p2, whiteGlow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
