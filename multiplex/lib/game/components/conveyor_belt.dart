import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

typedef NumberCompleteCallback = void Function(int value, Vector2 position);

class ConveyorBelt extends PositionComponent {
  final Vector2 gridPosition;
  final double speed;
  final List<Vector2> _beltPath;
  final NumberCompleteCallback? onNumberComplete;
  late Path _path;
  final List<MovingNumber> _numbers = [];
  final Paint _beltPaint = Paint()
    ..color = Colors.grey.withAlpha(100)
    ..style = PaintingStyle.fill;
  final Paint _arrowPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  ConveyorBelt({
    required this.gridPosition,
    required List<Vector2> path,
    this.speed = 100.0,
    this.onNumberComplete,
  }) : _beltPath = path,
       super(position: gridPosition);

  @override
  Future<void> onLoad() async {
    _path = Path();
    if (_beltPath.isNotEmpty) {
      _path.moveTo(_beltPath.first.x, _beltPath.first.y);
      for (var i = 1; i < _beltPath.length; i++) {
        _path.lineTo(_beltPath[i].x, _beltPath[i].y);
      }
    }
  }

  void addNumber(int value) {
    final number = MovingNumber(
      value: value,
      path: _beltPath,
      speed: speed,
      onComplete: (position) {
        onNumberComplete?.call(value, position);
      },
    );
    _numbers.add(number);
    add(number);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw the belt path
    if (_beltPath.length >= 2) {
      for (int i = 0; i < _beltPath.length - 1; i++) {
        final start = _beltPath[i];
        final end = _beltPath[i + 1];
        
        // Draw belt segment
        canvas.drawLine(start.toOffset(), end.toOffset(), _beltPaint);

        // Calculate arrow direction
        final direction = (end - start).normalized();
        final midPoint = start + (end - start) * 0.5;

        // Draw arrow head
        final arrowLength = 10.0;
        final arrowAngle = math.atan2(direction.y, direction.x);
        final arrowP1 = Vector2(
          midPoint.x - math.cos(arrowAngle - 0.5) * arrowLength,
          midPoint.y - math.sin(arrowAngle - 0.5) * arrowLength,
        );
        final arrowP2 = Vector2(
          midPoint.x - math.cos(arrowAngle + 0.5) * arrowLength,
          midPoint.y - math.sin(arrowAngle + 0.5) * arrowLength,
        );

        // Draw arrow
        canvas.drawPath(
          Path()
            ..moveTo(midPoint.x, midPoint.y)
            ..lineTo(arrowP1.x, arrowP1.y)
            ..moveTo(midPoint.x, midPoint.y)
            ..lineTo(arrowP2.x, arrowP2.y),
          _arrowPaint,
        );
      }
    }
  }
}

class MovingNumber extends PositionComponent {
  final int value;
  final List<Vector2> path;
  final double speed;
  final void Function(Vector2 position)? onComplete;
  int _currentPathIndex = 0;
  double _progress = 0.0;
  late TextComponent _label;

  MovingNumber({
    required this.value,
    required this.path,
    required this.speed,
    this.onComplete,
  }) : super(position: path.first);

  @override
  Future<void> onLoad() async {
    _label = TextComponent(
      text: value.toString(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _label.position = Vector2(-_label.size.x / 2, -_label.size.y / 2);
    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_currentPathIndex >= path.length - 1) {
      onComplete?.call(position);
      removeFromParent();
      return;
    }

    final start = path[_currentPathIndex];
    final end = path[_currentPathIndex + 1];
    final segmentLength = (end - start).length;

    _progress += (speed * dt) / segmentLength;

    if (_progress >= 1.0) {
      _progress = 0.0;
      _currentPathIndex++;
      if (_currentPathIndex >= path.length - 1) {
        onComplete?.call(position);
        removeFromParent();
        return;
      }
    } else {
      position = start + (end - start) * _progress;
    }
  }
}
