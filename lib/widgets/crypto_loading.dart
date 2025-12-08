import 'package:flutter/material.dart';

/// A cryptocurrency-style loading indicator widget
/// This can be used globally throughout the app
class CryptoLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const CryptoLoading({
    super.key,
    this.size = 40.0,
    this.color,
  });

  @override
  State<CryptoLoading> createState() => _CryptoLoadingState();
}

class _CryptoLoadingState extends State<CryptoLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.black;
    final size = widget.size;
    final segmentCount = 12;
    final segmentAngle = 2 * 3.14159 / segmentCount;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CryptoLoadingPainter(
              progress: _controller.value,
              color: color,
              segmentCount: segmentCount,
              segmentAngle: segmentAngle,
            ),
          );
        },
      ),
    );
  }
}

class _CryptoLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int segmentCount;
  final double segmentAngle;

  _CryptoLoadingPainter({
    required this.progress,
    required this.color,
    required this.segmentCount,
    required this.segmentAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentLength = radius * 0.4;
    final segmentWidth = 2.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = segmentWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < segmentCount; i++) {
      final angle = i * segmentAngle - 3.14159 / 2; // Start from top
      final adjustedProgress = (progress + i / segmentCount) % 1.0;
      
      // Calculate opacity based on position in rotation
      // The darkest segment is at progress, fading as we move away
      final distanceFromActive = (adjustedProgress - 0.5).abs() * 2;
      final opacity = (1.0 - distanceFromActive).clamp(0.0, 1.0);
      
      // Apply easing to opacity for smoother gradient
      final easedOpacity = opacity * opacity;
      
      paint.color = color.withOpacity(0.1 + easedOpacity * 0.9);

      final startAngle = angle;
      final endAngle = angle + segmentAngle * 0.7; // Make segments shorter
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - segmentLength),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CryptoLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

