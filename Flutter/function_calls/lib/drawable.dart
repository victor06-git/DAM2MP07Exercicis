import 'package:flutter/material.dart';

abstract class Drawable {
  void draw(Canvas canvas);
  void drawSelected(Canvas canvas) {
    // Default highlight - can be overridden by subclasses
  }
}

class Line extends Drawable {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  Line({
    required this.start,
    required this.end,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawLine(start, end, paint);
  }

  @override
  void drawSelected(Canvas canvas) {
    // Esta es la función que se usa para dibujar la selección
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0;
    canvas.drawLine(start, end, paint);
  }
}

class Rectangle extends Drawable {
  final Offset topLeft;
  final Offset bottomRight;
  final Color? color;
  final double strokeWidth;
  final List<Color>? gradientColors;

  Rectangle({
    required this.topLeft,
    required this.bottomRight,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.gradientColors,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final paint = Paint();

    if (gradientColors != null && gradientColors!.isNotEmpty) {
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors!,
      );
      paint.shader = gradient.createShader(rect);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = color!;
      paint.strokeWidth = strokeWidth;
      paint.style = PaintingStyle.stroke;
    }

    canvas.drawRect(rect, paint);
  }

  @override
  void drawSelected(Canvas canvas) {
    // Esta es la función que se usa para dibujar la selección
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect.inflate(3.0), paint);
  }
}

class Circle extends Drawable {
  final Offset center;
  final double radius;
  final Color? color;
  final double strokeWidth;
  final List<Color>? gradientColors;

  Circle({
    required this.center,
    required this.radius,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.gradientColors,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint();

    if (gradientColors != null && gradientColors!.isNotEmpty) {
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors!,
      );
      paint.shader = gradient.createShader(rect);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = color!;
      paint.style = PaintingStyle.fill;
    }

    canvas.drawCircle(center, radius, paint);
  }

  @override
  void drawSelected(Canvas canvas) {
    // Esta es la función que se usa para dibujar la selección
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius + 3, paint);
  }
}

class TextElement extends Drawable {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  TextElement({
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });

  @override
  void draw(Canvas canvas) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}
