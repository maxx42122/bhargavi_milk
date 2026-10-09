import 'package:flutter/material.dart';

/// Renders the BVH / MilkRoute brand logo with crystal-clear visibility,
/// authentic colors, and optional card container.
class BvhLogoWidget extends StatelessWidget {
  final double size;
  final bool showCard;
  final bool useFullLogo;
  final Color? cardColor;

  const BvhLogoWidget({
    super.key,
    this.size = 140,
    this.showCard = false,
    this.useFullLogo = false,
    this.cardColor,
    Animation<double>? shimmerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Raw Logo Image with guaranteed vector fallback
    Widget logoImage = useFullLogo
        ? Image.asset(
            'assets/images/logo_bvh_full.png',
            width: size * 1.5,
            height: size * 1.1,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (ctx, err, stack) => _buildVectorFallback(size),
          )
        : Image.asset(
            'assets/images/logo_v_3d.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (ctx, err, stack) => _buildVectorFallback(size),
          );

    if (!showCard) {
      return RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: logoImage,
        ),
      );
    }

    // 2. Optional frosted white container for high contrast
    return RepaintBoundary(
      child: Container(
        width: useFullLogo ? size * 1.8 : size * 1.35,
        height: size * 1.35,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          color: cardColor ?? Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(size * 0.25),
          border: Border.all(color: Colors.white, width: 2.0),
          boxShadow: [
            // Vibrant Cyan/Blue ambient glow
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
            // Deep navy drop shadow
            BoxShadow(
              color: const Color(0xFF1A1F4E).withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(child: logoImage),
      ),
    );
  }

  Widget _buildVectorFallback(double size) {
    return RepaintBoundary(
      child: CustomPaint(size: Size(size, size), painter: BvhVectorLogoPainter()),
    );
  }
}

/// Pristine vector custom painter for the 3D V + Fluid Wave logo.
class BvhVectorLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw "V" Base Shadow / Depth
    final vDepthPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final vDepthPath = Path();
    vDepthPath.moveTo(w * 0.12, h * 0.16);
    vDepthPath.lineTo(w * 0.38, h * 0.16);
    vDepthPath.lineTo(w * 0.50, h * 0.88);
    vDepthPath.lineTo(w * 0.62, h * 0.16);
    vDepthPath.lineTo(w * 0.88, h * 0.16);
    vDepthPath.lineTo(w * 0.58, h * 0.94);
    vDepthPath.quadraticBezierTo(w * 0.50, h * 1.0, w * 0.42, h * 0.94);
    vDepthPath.close();
    canvas.drawPath(vDepthPath, vDepthPaint);

    // 2. Draw Main "V" Shape
    final vMainPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E88E5), Color(0xFF1565C0), Color(0xFF0D47A1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final vPath = Path();
    // Top-left wing
    vPath.moveTo(w * 0.12, h * 0.14);
    vPath.lineTo(w * 0.38, h * 0.14);
    // Down to center point
    vPath.lineTo(w * 0.50, h * 0.86);
    // Up to top-right wing
    vPath.lineTo(w * 0.62, h * 0.14);
    vPath.lineTo(w * 0.88, h * 0.14);
    // Outer down right
    vPath.lineTo(w * 0.58, h * 0.92);
    // Rounded bottom vertex
    vPath.quadraticBezierTo(w * 0.50, h * 0.98, w * 0.42, h * 0.92);
    vPath.close();

    canvas.drawPath(vPath, vMainPaint);

    // 3. Draw Fluid Liquid Wave across the center of the V
    final wavePath = Path();
    final waveStart = Offset(w * 0.04, h * 0.46);
    wavePath.moveTo(waveStart.dx, waveStart.dy);

    // Smooth fluid S-curve across the V
    wavePath.cubicTo(
      w * 0.28,
      h * 0.36,
      w * 0.40,
      h * 0.64,
      w * 0.68,
      h * 0.52,
    );
    wavePath.cubicTo(
      w * 0.82,
      h * 0.44,
      w * 0.92,
      h * 0.42,
      w * 0.96,
      h * 0.46,
    );

    // Thickness of the wave
    wavePath.lineTo(w * 0.96, h * 0.54);
    wavePath.cubicTo(
      w * 0.90,
      h * 0.50,
      w * 0.80,
      h * 0.52,
      w * 0.66,
      h * 0.60,
    );
    wavePath.cubicTo(
      w * 0.38,
      h * 0.74,
      w * 0.26,
      h * 0.46,
      w * 0.04,
      h * 0.54,
    );
    wavePath.close();

    // Wave Shadow
    final waveShadowPaint = Paint()
      ..color = const Color(0xFF0F3D66).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(wavePath, waveShadowPaint);

    // Wave Gradient Fill (Cyan to Vibrant Blue)
    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF29B6F6), Color(0xFF1E88E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(wavePath, wavePaint);

    // Wave Top Highlight / Specular Reflection
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.06, h * 0.47);
    highlightPath.cubicTo(
      w * 0.28,
      h * 0.38,
      w * 0.40,
      h * 0.62,
      w * 0.68,
      h * 0.51,
    );
    highlightPath.cubicTo(
      w * 0.80,
      h * 0.43,
      w * 0.90,
      h * 0.42,
      w * 0.94,
      h * 0.45,
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
