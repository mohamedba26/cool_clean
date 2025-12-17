import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

/// Circular loading indicator with gradient
class GradientCircularProgress extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Gradient? gradient;

  const GradientCircularProgress({
    Key? key,
    this.size = 40,
    this.strokeWidth = 4,
    this.gradient,
  }) : super(key: key);

  @override
  State<GradientCircularProgress> createState() =>
      _GradientCircularProgressState();
}

class _GradientCircularProgressState extends State<GradientCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: GradientCircularProgressPainter(
              gradient: widget.gradient ?? primaryGradient,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class GradientCircularProgressPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;

  GradientCircularProgressPainter({
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - strokeWidth / 2,
      ),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wave loading animation
class WaveLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const WaveLoadingAnimation({
    Key? key,
    this.size = 60,
    this.color,
  }) : super(key: key);

  @override
  State<WaveLoadingAnimation> createState() => _WaveLoadingAnimationState();
}

class _WaveLoadingAnimationState extends State<WaveLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBar(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.15;
        final value = math.sin((_controller.value + delay) * 2 * math.pi);
        final height = widget.size * 0.4 + (widget.size * 0.3 * value.abs());

        return Container(
          width: widget.size * 0.15,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.color ?? AppColors.primaryStart,
                (widget.color ?? AppColors.primaryStart).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(widget.size * 0.075),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (index) => _buildBar(index)),
      ),
    );
  }
}

/// Dots loading animation
class DotsLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const DotsLoadingAnimation({
    Key? key,
    this.size = 12,
    this.color,
  }) : super(key: key);

  @override
  State<DotsLoadingAnimation> createState() => _DotsLoadingAnimationState();
}

class _DotsLoadingAnimationState extends State<DotsLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = ((_controller.value + delay) % 1.0);
        final scale = 0.5 + (0.5 * (1 - (value - 0.5).abs() * 2));

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color ?? AppColors.primaryStart,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.size * 0.25),
          child: _buildDot(index),
        ),
      ),
    );
  }
}
