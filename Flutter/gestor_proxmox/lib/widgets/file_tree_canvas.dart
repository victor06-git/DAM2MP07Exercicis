import 'package:flutter/material.dart';

/// Simple visualizador de árbol de carpetas usando Canvas.
class FileTreeCanvas extends StatelessWidget {
  final Map<String, dynamic> tree; // recursive map: {name: {child1: {...}}}
  const FileTreeCanvas({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TreePainter(tree),
      size: const Size(double.infinity, 300),
    );
  }
}

class _TreePainter extends CustomPainter {
  final Map<String, dynamic> tree;
  _TreePainter(this.tree);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueGrey.shade700;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double x = 16;
    double y = 16;

    void drawNode(
      String name,
      Map<String, dynamic>? children,
      double cx,
      double cy,
      int depth,
    ) {
      final radius = 10.0;
      final nodePaint = Paint()..color = Colors.blueAccent;
      canvas.drawCircle(Offset(cx, cy), radius, nodePaint);
      textPainter.text = TextSpan(
        text: name,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx + radius + 6, cy - textPainter.height / 2),
      );

      if (children != null && children.isNotEmpty) {
        double childX = cx + 120;
        double childY = cy - (children.length - 1) * 20;
        children.forEach((k, v) {
          canvas.drawLine(
            Offset(cx + radius, cy),
            Offset(childX - radius, childY),
            paint,
          );
          drawNode(
            k,
            v is Map<String, dynamic> ? v : null,
            childX,
            childY,
            depth + 1,
          );
          childY += 40;
        });
      }
    }

    tree.forEach((k, v) {
      drawNode(k, v is Map<String, dynamic> ? v : null, x, y, 0);
      y += 80;
    });
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) =>
      oldDelegate.tree != tree;
}
