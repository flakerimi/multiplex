import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FactoryComponent extends PositionComponent {
  int targetNumber;
  int targetValue;
  int currentValue;
  int level;

  FactoryComponent({
    required Vector2 position,
    required Vector2 size,
    this.targetNumber = 1,
    this.targetValue = 10,
    this.currentValue = 0,
    this.level = 1,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = size.toRect();

    // Draw a fully opaque rectangular background first to cover grid
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1976D2) // Solid blue background
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, backgroundPaint);

    // Then draw rounded rectangle on top
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12.0));

    // Draw factory background with gradient
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF64B5F6), // Light blue at top
          Color(0xFF1976D2), // Darker blue at bottom
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Draw border with rounded corners
    final borderPaint = Paint()
      ..color = const Color(0xFF0D47A1) // Dark blue border
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    canvas.drawRRect(rrect, borderPaint);

    // Calculate positions
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final tileSize = size.x / 5; // Factory is 5x5

    // Calculate font sizes based on tile size
    final double targetNumberFontSize = tileSize * 1.2;
    final double progressFontSize = tileSize * 0.6;
    final double levelFontSize = tileSize * 0.35;
    final double smallTextFontSize = tileSize * 0.25;

    // Draw target number (big white number at top)
    TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: targetNumberFontSize,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      '$targetNumber',
      Vector2(centerX, centerY - tileSize * 0.9),
      anchor: Anchor.center,
    );

    // Draw progress (green 0/10)
    TextPaint(
      style: TextStyle(
        color: const Color(0xFF66BB6A), // Green
        fontSize: progressFontSize,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      '$currentValue/$targetValue',
      Vector2(centerX, centerY - tileSize * 0.1),
      anchor: Anchor.center,
    );

    // Draw level
    TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: levelFontSize,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      'LEVEL $level',
      Vector2(centerX, centerY + tileSize * 0.5),
      anchor: Anchor.center,
    );

    // Draw additional info at bottom
    final smallTextPaint = TextPaint(
      style: TextStyle(
        color: Colors.white70,
        fontSize: smallTextFontSize,
        fontWeight: FontWeight.normal,
      ),
    );

    smallTextPaint.render(
      canvas,
      'ADDER',
      Vector2(centerX, centerY + tileSize * 0.85),
      anchor: Anchor.center,
    );

    smallTextPaint.render(
      canvas,
      'UNLOCKED',
      Vector2(centerX, centerY + tileSize * 1.1),
      anchor: Anchor.center,
    );

    smallTextPaint.render(
      canvas,
      'NEXT LEVEL',
      Vector2(centerX, centerY + tileSize * 1.35),
      anchor: Anchor.center,
    );
  }
}
