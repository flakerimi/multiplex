import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class NumberTile extends PositionComponent {
  static const double tileSize = 64.0;
  final int value;
  late TextComponent _label;
  bool isChained = false;

  NumberTile({
    required this.value,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(tileSize),
        );

  @override
  Future<void> onLoad() async {
    // Add background
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFFB22222)
        ..style = PaintingStyle.fill,
    ));

    // Add number label
    _label = TextComponent(
      text: value.toString(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _label.position = size / 2 - _label.size / 2;
    add(_label);

    // Add border
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white.withAlpha(51)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
  }

  void chain() {
    isChained = true;
    // Add visual indicator for chained state
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.yellow.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    ));
  }

  void unchain() {
    isChained = false;
    // Remove visual indicators
    children.whereType<RectangleComponent>().where((c) => 
      c.paint.color == Colors.yellow.withAlpha(100)
    ).forEach(remove);
  }
}
