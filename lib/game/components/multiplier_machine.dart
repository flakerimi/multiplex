import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:multiplex/game/models/operation.dart';

class MultiplierMachine extends PositionComponent {
  final Vector2 gridPosition;
  final Operation operation;
  final Function(int)? onResult;
  late TextComponent _label;

  MultiplierMachine({
    required this.gridPosition,
    required this.operation,
    this.onResult,
  }) : super(
          size: Vector2.all(80.0),
          position: gridPosition * 80.0,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.orange.withAlpha(179)
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
    _label.position = size / 2;
    _label.anchor = Anchor.center;
    add(_label);
  }

  // void receiveNumber(int number) {
  //   _inputs.add(number);
  //   if (_inputs.length == 2) {
  //     final result = operation
  //         .execute(_inputs[0].toDouble(), _inputs[1].toDouble())
  //         .toInt();
  //     onResult?.call(result);
  //     _inputs.clear();
  //   }
  // }
}
