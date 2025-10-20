import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ScoreDisplay extends PositionComponent {
  int _score;
  late TextComponent _label;

  ScoreDisplay({
    required Vector2 position,
    int initialScore = 0,
  })  : _score = initialScore,
        super(
          position: position,
          size: Vector2(200, 40),
        );

  set score(int value) {
    _score = value;
    _updateText();
  }

  void _updateText() {
    _label.text = 'Score: ${_score.toStringAsFixed(0)}';
  }

  @override
  Future<void> onLoad() async {
    _label = TextComponent(
      text: 'Score: ${_score.toStringAsFixed(0)}',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
    add(_label);
  }
}
