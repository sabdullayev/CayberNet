import 'package:flutter/material.dart';
import '../theme/cyber_colors.dart';
import '../theme/cyber_typography.dart';

class CyberButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accentColor;
  final bool isOutlined;
  final bool isLoading;
  final double height;
  final double cutRadius;
  final String? hudLabel;

  const CyberButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.accentColor = CyberColors.neonCrimson,
    this.isOutlined = false,
    this.isLoading = false,
    this.height = 48,
    this.cutRadius = 8,
    this.hudLabel,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final Color effectiveColor = enabled ? widget.accentColor : CyberColors.textMuted;

    final shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(widget.cutRadius),
        bottomRight: Radius.circular(widget.cutRadius),
        topRight: const Radius.circular(2),
        bottomLeft: const Radius.circular(2),
      ),
      side: BorderSide(
        color: _isPressed ? Colors.white : effectiveColor,
        width: _isPressed ? 1.8 : 1.2,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled
          ? (_) {
              _glowController.forward();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: enabled
          ? (_) {
              _glowController.reverse();
              setState(() => _isPressed = false);
            }
          : null,
      onTapCancel: enabled
          ? () {
              _glowController.reverse();
              setState(() => _isPressed = false);
            }
          : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: widget.height,
            decoration: ShapeDecoration(
              shape: shape,
              gradient: widget.isOutlined
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectiveColor.withValues(alpha: _isPressed ? 0.38 : 0.22),
                        effectiveColor.withValues(alpha: _isPressed ? 0.22 : 0.08),
                      ],
                    ),
              color: widget.isOutlined
                  ? CyberColors.voidBackground.withValues(alpha: 0.7)
                  : null,
              shadows: enabled
                  ? [
                      BoxShadow(
                        color: effectiveColor.withValues(
                          alpha: _isPressed ? _glowAnimation.value : 0.2,
                        ),
                        blurRadius: _isPressed ? 18 : 10,
                        spreadRadius: _isPressed ? 1 : -1,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: _isPressed ? Colors.white : effectiveColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            Text(
                              '▶',
                              style: TextStyle(
                                color: effectiveColor,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.text.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CyberTypography.monoBold.copyWith(
                                color: _isPressed ? Colors.white : CyberColors.textPrimary,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
