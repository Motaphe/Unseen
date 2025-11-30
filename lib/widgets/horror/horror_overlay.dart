import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:unseen/config/theme.dart';

/// Lightweight animated vignette/static overlay to add subtle horror atmosphere.
class HorrorOverlay extends StatefulWidget {
  final double intensity; // 0-1 for darkness amount
  final bool flicker;

  const HorrorOverlay({
    super.key,
    this.intensity = 0.3,
    this.flicker = true,
  });

  @override
  State<HorrorOverlay> createState() => _HorrorOverlayState();
}

class _HorrorOverlayState extends State<HorrorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final flicker = widget.flicker
              ? (0.02 * _random.nextDouble())
              : 0.0;
          final opacity = (widget.intensity + flicker).clamp(0.1, 0.6);

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: opacity),
                  Colors.black.withValues(alpha: opacity + 0.15),
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
            child: CustomPaint(
              painter: _StaticNoisePainter(
                opacity: opacity * 0.4,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaticNoisePainter extends CustomPainter {
  final double opacity;
  final Random _random = Random();

  _StaticNoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = UnseenTheme.bloodRed.withValues(alpha: opacity)
      ..strokeWidth = 1;

    // Draw sparse static noise to avoid performance cost
    for (int i = 0; i < 60; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      canvas.drawPoints(ui.PointMode.points, [Offset(dx, dy)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
