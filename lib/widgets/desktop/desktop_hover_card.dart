import 'package:flutter/material.dart';
import '../../core/colors.dart';

/// An interactive card widget designed for Desktop web layouts with
/// smooth hover elevation, border illumination, and cursor feedback.
class DesktopHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;
  final Border? border;
  final bool enableHoverLift;
  final double hoverElevation;

  const DesktopHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor,
    this.borderRadius = AppColors.cardRadius,
    this.border,
    this.enableHoverLift = true,
    this.hoverElevation = 18.0,
  });

  @override
  State<DesktopHoverCard> createState() => _DesktopHoverCardState();
}

class _DesktopHoverCardState extends State<DesktopHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final defaultBg = widget.backgroundColor ?? AppColors.cardSurface;
    final isInteractive = widget.onTap != null;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translateByDouble(
                0.0,
                _isHovered && widget.enableHoverLift ? -3.0 : 0.0,
                0.0,
                0.0,
              ),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: defaultBg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.border ??
                  Border.all(
                    color: _isHovered
                        ? AppColors.milkBlue600.withValues(alpha: 0.35)
                        : AppColors.border,
                    width: 1,
                  ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? AppColors.milkBlue900.withValues(alpha: 0.08)
                      : AppColors.darkNavy.withValues(alpha: 0.03),
                  blurRadius: _isHovered ? widget.hoverElevation : 10.0,
                  offset: Offset(0, _isHovered ? 8 : 3),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: AppColors.milkBlue600.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
