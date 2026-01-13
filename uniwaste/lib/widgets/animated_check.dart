import 'package:flutter/material.dart';

class AnimatedCheck extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedCheck({super.key, this.size = 80, this.color = const Color(0xFF6B8E23)}); // Default to your theme green

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: CheckPainter(progress: _animation.value, color: widget.color),
          );
        },
      ),
    );
  }
}

class CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width / 12 // Dynamic stroke width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Define the checkmark shape (relative to size)
    path.moveTo(size.width * 0.25, size.height * 0.55);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.75, size.height * 0.30);

    // Compute metrics to animate the path drawing
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
    
    // Optional: Draw a fading background circle
    final circlePaint = Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill;
        
    // Animate circle growing
    canvas.drawCircle(
      Offset(size.width/2, size.height/2), 
      (size.width/2) * progress, 
      circlePaint
    );
  }

  @override
  bool shouldRepaint(covariant CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}