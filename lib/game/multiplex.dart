import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'components/operation_tile.dart';
import 'components/number_tile.dart';
import 'models/operation.dart';

class Multiplex extends FlameGame with DragCallbacks {
  static const int gridSize = 15;
  static const double tileSize = 64.0;
  
  final List<List<Component?>> grid = List.generate(
    gridSize,
    (_) => List.filled(gridSize, null),
  );
  
  List<NumberTile> chainedTiles = [];
  Operation? selectedOperation;
  double score = 0;
  int targetNumber = 3;
  
  @override
  Color backgroundColor() => const Color(0xFF90EE90);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.zoom = 1.0;
    
    // Add operations panel
    final operations = [
      Operation.add,
      Operation.subtract,
      Operation.multiply,
      Operation.divide,
    ];
    
    for (var i = 0; i < operations.length; i++) {
      final op = OperationTile(
        operation: operations[i],
        position: Vector2(
          gridSize * tileSize + 20,
          20 + i * (tileSize + 10),
        ),
      );
      add(op);
    }
    
    // Add initial number tiles
    _addNumberTile(1, Vector2(1, 1));
    _addNumberTile(1, Vector2(2, 1));
    _addNumberTile(1, Vector2(3, 1));
    _addNumberTile(2, Vector2(1, 3));
    _addNumberTile(2, Vector2(2, 3));
    
    // Add target display
    add(
      TextComponent(
        text: 'Target: $targetNumber',
        position: Vector2(gridSize * tileSize + 20, gridSize * tileSize - 100),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF663399),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _addNumberTile(int value, Vector2 gridPos) {
    final tile = NumberTile(
      value: value,
      position: gridPos * tileSize,
    );
    grid[gridPos.y.toInt()][gridPos.x.toInt()] = tile;
    add(tile);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    
    final gridPos = Vector2(
      (event.canvasPosition.x / tileSize).floor().toDouble(),
      (event.canvasPosition.y / tileSize).floor().toDouble()
    );
    
    final component = grid[gridPos.y.toInt()][gridPos.x.toInt()];
    
    if (component is NumberTile) {
      chainedTiles = [component];
      component.chain();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    
    if (chainedTiles.isEmpty) return;
    
    final gridPos = Vector2(
      (event.canvasPosition.x / tileSize).floor().toDouble(),
      (event.canvasPosition.y / tileSize).floor().toDouble()
    );
    
    final component = grid[gridPos.y.toInt()][gridPos.x.toInt()];
    
    if (component is NumberTile && 
        component.value == chainedTiles.first.value &&
        !chainedTiles.contains(component)) {
      // Check if the new tile is adjacent to the last chained tile
      final lastTile = chainedTiles.last;
      final lastPos = Vector2(
        lastTile.position.x / tileSize,
        lastTile.position.y / tileSize
      );
      final dx = (gridPos.x - lastPos.x).abs();
      final dy = (gridPos.y - lastPos.y).abs();
      
      if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1)) {
        chainedTiles.add(component);
        component.chain();
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    
    // Unchain all tiles
    for (final tile in chainedTiles) {
      tile.unchain();
    }
    chainedTiles.clear();
  }
}
