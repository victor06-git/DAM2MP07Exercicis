import 'package:flutter/rendering.dart';

import 'drawable.dart';

class CanvasPainter extends CustomPainter {
  final List<Drawable> drawables;
  final int? selectedIndex;

  CanvasPainter({required this.drawables, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawables.length; i++) {
      drawables[i].draw(canvas);
      if (selectedIndex == i) {
        drawables[i].drawSelected(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
