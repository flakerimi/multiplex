import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../models/operation.dart';

class Factory extends Component with DragCallbacks {
  final int targetNumber;
  final List<Operation> availableNumbers;
  final List<Vector2> conveyorPoints;
  final void Function() onLevelComplete;
  late Vector2 size;

  late final ExtractorComponent extractor;
  late final AdderComponent adder;
  late final List<ConveyorBelt> conveyors;
  late final List<NumberBlock> numberBlocks;
  late final List<OperationBlock> operations;

  Factory({
    required this.targetNumber,
    required this.availableNumbers,
    required this.conveyorPoints,
    required this.onLevelComplete,
    Vector2? size,
  }) {
    this.size = size ?? Vector2(800, 600); // Default size if none provided
  }

  @override
  Future<void> onLoad() async {
    // Add extractor at the top
    extractor = ExtractorComponent(
      position: Vector2(300, 50),
      availableNumbers: availableNumbers,
    );
    add(extractor);

    // Add adder at the bottom
    adder = AdderComponent(
      position: Vector2(300, 400),
      targetNumber: targetNumber,
    );
    add(adder);

    // Create conveyor belts between points
    conveyors = [];
    for (int i = 0; i < conveyorPoints.length - 1; i++) {
      final conveyor = ConveyorBelt(
        start: conveyorPoints[i],
        end: conveyorPoints[i + 1],
      );
      conveyors.add(conveyor);
      add(conveyor);
    }

    // Add number blocks
    numberBlocks = [];
    for (var operation in availableNumbers) {
      final block = NumberBlock(
        number: operation.value,
        position: Vector2(50 + numberBlocks.length * 100, 50),
        size: Vector2.all(32),
      );
      numberBlocks.add(block);
      add(block);
    }

    // Add operation blocks on the right side
    operations = [
      OperationBlock(
        operation: '+',
        position: Vector2(size.x - 150, 50),
        size: Vector2.all(32),
      ),
      OperationBlock(
        operation: '-',
        position: Vector2(size.x - 150, 100),
        size: Vector2.all(32),
      ),
      OperationBlock(
        operation: '*',
        position: Vector2(size.x - 150, 150),
        size: Vector2.all(32),
      ),
      OperationBlock(
        operation: '÷',
        position: Vector2(size.x - 150, 200),
        size: Vector2.all(32),
      ),
    ];

    for (var op in operations) {
      add(op);
    }
  }
}

class ExtractorComponent extends PositionComponent with DragCallbacks {
  final List<Operation> availableNumbers;
  Operation? currentNumber;

  ExtractorComponent({
    required Vector2 position,
    required this.availableNumbers,
  }) : super(position: position, size: Vector2.all(64));

  @override
  void render(Canvas canvas) {
    // Draw extractor machine
    final paint = Paint()..color = Colors.grey;
    canvas.drawRect(size.toRect(), paint);

    // Draw available number
    if (currentNumber != null) {
      final textConfig = TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      );
      textConfig.render(
        canvas,
        currentNumber!.symbol,
        Vector2(size.x / 2, size.y / 2),
      );
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    if (currentNumber != null) {
      // Create a new number component that can be dragged
      final numberComponent = NumberComponent(
        number: currentNumber!,
        position: position,
      );
      parent?.add(numberComponent);
      return true;
    }
    return false;
  }
}

class AdderComponent extends PositionComponent {
  final int targetNumber;
  int currentSum = 0;

  AdderComponent({
    required Vector2 position,
    required this.targetNumber,
  }) : super(position: position, size: Vector2.all(80));

  @override
  void render(Canvas canvas) {
    // Draw adder machine
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(size.toRect(), paint);

    // Draw current sum and target
    final textConfig = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    );
    textConfig.render(
      canvas,
      '$currentSum/$targetNumber',
      Vector2(size.x / 2, size.y / 2),
    );
  }

  void addNumber(int number) {
    currentSum += number;
    if (currentSum == targetNumber) {
      // Level completed!
      parent?.parent?.add(
        TextComponent(
          text: 'Level Complete!',
          position: Vector2(400, 300),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.green,
              fontSize: 48,
            ),
          ),
        ),
      );
      (parent as Factory).onLevelComplete();
    }
  }
}

class ConveyorBelt extends PositionComponent {
  final Vector2 start;
  final Vector2 end;

  ConveyorBelt({
    required this.start,
    required this.end,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      start.toOffset(),
      end.toOffset(),
      paint,
    );
  }

  bool isOnBelt(Vector2 position) {
    // Check if a position is on this conveyor belt
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = Vector2(dx, dy).length;

    final t = ((position.x - start.x) * dx + (position.y - start.y) * dy) /
        (length * length);
    return t >= 0 && t <= 1;
  }
}

class NumberComponent extends PositionComponent with DragCallbacks {
  final Operation number;

  NumberComponent({
    required this.number,
    required Vector2 position,
  }) : super(position: position, size: Vector2.all(40));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = number.color;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );

    final textConfig = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    );
    textConfig.render(
      canvas,
      number.symbol,
      Vector2(size.x / 2, size.y / 2),
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.delta;

    // Check if we're on a conveyor belt
    final factory = findParent<Factory>();
    if (factory != null) {
      for (final conveyor in factory.conveyors) {
        if (conveyor.isOnBelt(position)) {
          // Snap to conveyor line
          position = _snapToLine(
            conveyor.start,
            conveyor.end,
            position,
          );
          break;
        }
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // Check if we're near the adder
    final factory = findParent<Factory>();
    if (factory != null) {
      final distance = (position - factory.adder.position).length;
      if (distance < 40) {
        factory.adder.addNumber(int.parse(number.symbol));
        removeFromParent();
      }
    }
  }

  Vector2 _snapToLine(Vector2 start, Vector2 end, Vector2 point) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = Vector2(dx, dy).length;

    final t = ((point.x - start.x) * dx + (point.y - start.y) * dy) /
        (length * length);
    return Vector2(
      start.x + t * dx,
      start.y + t * dy,
    );
  }
}

class NumberBlock extends PositionComponent with DragCallbacks {
  final int number;
  final Paint _paint = Paint()..color = Colors.brown;
  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
    ),
  );

  NumberBlock({
    required this.number,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
    _textPaint.render(
      canvas,
      number.toString(),
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }
}

class OperationBlock extends PositionComponent with DragCallbacks {
  final String operation;
  final Paint _paint = Paint()..color = Colors.orange;
  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      color: Colors.black,
      fontSize: 16,
    ),
  );

  OperationBlock({
    required this.operation,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
    _textPaint.render(
      canvas,
      operation,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );
  }
}
