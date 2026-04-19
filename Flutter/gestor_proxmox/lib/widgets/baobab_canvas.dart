import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/disk_usage_node.dart';

class BaobabCanvas extends StatelessWidget {
  const BaobabCanvas({super.key, required this.root});

  final DiskUsageNode root;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BaobabPainter(root),
      size: Size.infinite,
    );
  }
}

class _BaobabPainter extends CustomPainter {
  _BaobabPainter(this.root);

  final DiskUsageNode root;
  final List<Color> palette = const [
    Color(0xFF6CC070),
    Color(0xFF4DB6AC),
    Color(0xFF64B5F6),
    Color(0xFFFFB74D),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.46;
    const ringWidth = 28.0;
    _paintLevel(
      canvas: canvas,
      center: center,
      nodes: root.children,
      total: root.sizeKb <= 0 ? 1 : root.sizeKb,
      innerRadius: 28,
      ringWidth: ringWidth,
      depth: 0,
      maxRadius: maxRadius,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: '${root.name}\n${_formatSize(root.sizeKb)}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    )..layout(maxWidth: 110);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _paintLevel({
    required Canvas canvas,
    required Offset center,
    required List<DiskUsageNode> nodes,
    required int total,
    required double innerRadius,
    required double ringWidth,
    required int depth,
    required double maxRadius,
  }) {
    if (nodes.isEmpty || innerRadius > maxRadius) return;
    double startAngle = -math.pi / 2;
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final ratio = total <= 0 ? 0.0 : node.sizeKb / total;
      final sweep = (ratio * math.pi * 2).clamp(0.02, math.pi * 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth - 2
        ..color = palette[(depth + i) % palette.length];
      final rect = Rect.fromCircle(center: center, radius: innerRadius + ringWidth / 2);
      canvas.drawArc(rect, startAngle, sweep, false, paint);

      if (node.children.isNotEmpty) {
        _paintLevel(
          canvas: canvas,
          center: center,
          nodes: node.children,
          total: node.sizeKb <= 0 ? 1 : node.sizeKb,
          innerRadius: innerRadius + ringWidth,
          ringWidth: ringWidth,
          depth: depth + 1,
          maxRadius: maxRadius,
        );
      }
      startAngle += sweep;
    }
  }

  String _formatSize(int kb) {
    if (kb >= 1024 * 1024) {
      return '${(kb / (1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '$kb KB';
  }

  @override
  bool shouldRepaint(covariant _BaobabPainter oldDelegate) =>
      oldDelegate.root != root;
}
