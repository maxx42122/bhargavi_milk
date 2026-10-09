import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated multi-layered fluid wave widget representing fresh milk and dairy liquid flow.
class AnimatedFluidWaves extends StatelessWidget {
  final Animation<double> animation;
  final double height;
  final List<Color>? waveColors;

  const AnimatedFluidWaves({
    super.key,
    required this.animation,
    this.height = 160,
    this.waveColors,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _FluidWavePainter(
            animation: animation,
            waveColors: waveColors ??
                [
                  const Color(0xFF1B7BD6).withValues(alpha: 0.18),
                  const Color(0xFF3B94E8).withValues(alpha: 0.28),
                  const Color(0xFF70B8F8).withValues(alpha: 0.40),
                  Colors.white.withValues(alpha: 0.85),
                ],
          ),
        ),
      ),
    );
  }
}

class _FluidWavePainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> waveColors;

  _FluidWavePainter({
    required this.animation,
    required this.waveColors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    // Layer 1: Deep slow background wave
    _drawWave(
      canvas: canvas,
      size: size,
      color: waveColors[0],
      wavelength: size.width * 1.2,
      amplitude: 16.0,
      phase: t * 2 * math.pi * 0.8,
      baseY: size.height * 0.35,
    );

    // Layer 2: Middle rhythmic wave
    _drawWave(
      canvas: canvas,
      size: size,
      color: waveColors[1],
      wavelength: size.width * 0.9,
      amplitude: 20.0,
      phase: -t * 2 * math.pi * 1.1 + 1.2,
      baseY: size.height * 0.45,
    );

    // Layer 3: Cyan/Blue highlight wave
    _drawWave(
      canvas: canvas,
      size: size,
      color: waveColors[2],
      wavelength: size.width * 0.75,
      amplitude: 18.0,
      phase: t * 2 * math.pi * 1.4 + 2.5,
      baseY: size.height * 0.58,
    );

    // Layer 4: Top crisp milk foam / crest wave
    _drawWave(
      canvas: canvas,
      size: size,
      color: waveColors[3],
      wavelength: size.width * 0.6,
      amplitude: 14.0,
      phase: -t * 2 * math.pi * 1.6 + 3.8,
      baseY: size.height * 0.70,
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required Color color,
    required double wavelength,
    required double amplitude,
    required double phase,
    required double baseY,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    final step = math.max(12.0, size.width / 75.0);
    for (double x = 0; x <= size.width; x += step) {
      final y = baseY + amplitude * math.sin((x / wavelength) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    // Ensure smooth termination at right edge
    final finalY = baseY + amplitude * math.sin((size.width / wavelength) * 2 * math.pi + phase);
    path.lineTo(size.width, finalY);

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FluidWavePainter oldDelegate) => true;
}

/// Floating ambient bokeh / milk droplets effect.
class AmbientGlowParticles extends StatelessWidget {
  final Animation<double> animation;
  final int count;

  const AmbientGlowParticles({
    super.key,
    required this.animation,
    this.count = 14,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlesPainter(animation: animation, count: count),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final int count;
  late final List<_Particle> _particles;

  _ParticlesPainter({
    required this.animation,
    required this.count,
  }) : super(repaint: animation) {
    final rand = math.Random(42); // deterministic seed
    _particles = List.generate(count, (i) {
      return _Particle(
        relX: rand.nextDouble(),
        relY: rand.nextDouble(),
        radius: 3.0 + rand.nextDouble() * 8.0,
        speed: 0.3 + rand.nextDouble() * 0.7,
        alpha: 0.12 + rand.nextDouble() * 0.25,
        color: i % 3 == 0
            ? const Color(0xFF3B94E8)
            : (i % 3 == 1 ? const Color(0xFF6BD0FF) : Colors.white),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    for (final p in _particles) {
      final currentY = (p.relY - (t * p.speed)) % 1.0;
      final x = p.relX * size.width + math.sin(t * 2 * math.pi + p.relX * 10) * 12.0;
      final y = currentY * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

class _Particle {
  final double relX;
  final double relY;
  final double radius;
  final double speed;
  final double alpha;
  final Color color;

  _Particle({
    required this.relX,
    required this.relY,
    required this.radius,
    required this.speed,
    required this.alpha,
    required this.color,
  });
}
