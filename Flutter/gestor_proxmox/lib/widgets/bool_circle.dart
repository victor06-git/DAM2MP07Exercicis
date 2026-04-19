import 'package:flutter/material.dart';

class BoolCircle extends StatelessWidget {
  final bool value;
  final double size;

  const BoolCircle({super.key, required this.value, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BoolCirclePainter(value),
    );
  }
}

class _BoolCirclePainter extends CustomPainter {
  final bool value;
  _BoolCirclePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = value ? Colors.green : Colors.red
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius, paint);

    final border = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant _BoolCirclePainter oldDelegate) =>
      oldDelegate.value != value;
}
