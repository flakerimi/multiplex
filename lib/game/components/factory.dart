import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Factory extends PositionComponent {
  final Vector2 gridPosition;
  int _targetNumber;
  static const double factorySize = 192.0; // 3x3 grid tiles
  Function(int)? onTargetAchieved;
  late TextComponent _targetText;
  late TextComponent _progressText;
  late TextComponent _unlockText;

  Factory({
    required this.gridPosition,
    required int targetNumber,
    this.onTargetAchieved,
  }) : _targetNumber = targetNumber,
       super(
          size: Vector2.all(factorySize),
          position: gridPosition * (factorySize / 3),
        );

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = const Color(0xFF663399) // Purple color
        ..style = PaintingStyle.fill,
    ));

    _targetText = TextComponent(
      text: '$_targetNumber',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _targetText.position = Vector2(size.x / 2, size.y / 3) - _targetText.size / 2;
    add(_targetText);

    _progressText = TextComponent(
      text: '0/200',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _progressText.position = Vector2(size.x / 2, size.y * 2/3) - _progressText.size / 2;
    add(_progressText);

    _unlockText = TextComponent(
      text: 'unlocks $_targetNumber on grid',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
    _unlockText.position = Vector2(size.x / 2, size.y * 4/5) - _unlockText.size / 2;
    add(_unlockText);
  }

  void receiveNumber(int number) {
    if (number == _targetNumber) {
      onTargetAchieved?.call(number);
    }
  }

  set targetNumber(int value) {
    _targetNumber = value;
    if (isMounted) {
      _targetText.text = '$_targetNumber';
      _unlockText.text = 'unlocks $_targetNumber on grid';
    }
  }
}
