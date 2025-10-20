import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:multiplex/game/models/operation.dart';

class OperationTile extends PositionComponent {
  static const double tileSize = 64.0;
  final Operation operation;
  late TextComponent _label;

  OperationTile({
    required this.operation,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(tileSize),
        );

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFFFFAA00)
        ..style = PaintingStyle.fill,
    ));

    _label = TextComponent(
      text: operation.symbol,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _label.position = size / 2 - _label.size / 2;
    add(_label);

    // Add a border
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.black.withAlpha(51)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
  }
}
