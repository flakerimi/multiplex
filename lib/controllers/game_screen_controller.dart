import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../game/models/tile.dart';
import '../game/multiplex.dart';
import '../game/tool.dart';

class GameScreenController extends GetxController {
  final Multiplex game;

  final Rx<Offset> mousePosition = Offset.zero.obs;
  final Rx<Offset?> dragStartPosition = Rx<Offset?>(null);
  final RxBool hasUnsavedChanges = false.obs;
  final RxBool isRightClickDragging = false.obs;
  final Rx<Offset?> lastRightClickGridPos = Rx<Offset?>(null);

  GameScreenController({required this.game});

  /// Snap mouse position to grid cell center with axis locking
  Offset snapToGrid(Offset screenPosition) {
    final tileSize = game.tileSize;
    final gridOffset = game.gridOffset;

    // Convert screen position to grid coordinates
    var gridX = ((screenPosition.dx + gridOffset.x) / tileSize).floor();
    var gridY = ((screenPosition.dy + gridOffset.y) / tileSize).floor();

    // If dragging with belt tool, lock to axis based on belt direction
    if (dragStartPosition.value != null && game.inputManager.selectedTool == Tool.belt) {
      final startGridX = ((dragStartPosition.value!.dx + gridOffset.x) / tileSize).floor();
      final startGridY = ((dragStartPosition.value!.dy + gridOffset.y) / tileSize).floor();

      final beltDirection = game.inputManager.currentBeltDirection;

      // For horizontal belts (left/right), lock Y coordinate
      if (beltDirection == BeltDirection.left || beltDirection == BeltDirection.right) {
        gridY = startGridY;
      }
      // For vertical belts (up/down), lock X coordinate
      else {
        gridX = startGridX;
      }
    }

    // Convert back to screen position at the center of the grid cell
    final snappedX = gridX * tileSize - gridOffset.x + tileSize / 2;
    final snappedY = gridY * tileSize - gridOffset.y + tileSize / 2;

    return Offset(snappedX, snappedY);
  }

  void updateMousePosition(Offset position) {
    mousePosition.value = snapToGrid(position);
  }

  void startDrag(Offset position) {
    dragStartPosition.value = position;
    mousePosition.value = snapToGrid(position);
  }

  void endDrag() {
    dragStartPosition.value = null;
  }
}
