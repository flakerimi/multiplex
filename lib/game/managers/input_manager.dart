import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tile.dart';
import '../tool.dart';
import 'tile_manager.dart';

class InputManager {
  final TileManager tileManager;
  final Set<LogicalKeyboardKey> pressedKeys = {};

  // Use ValueNotifier for reactive state management
  final ValueNotifier<Tool> selectedToolNotifier = ValueNotifier(Tool.none);
  final ValueNotifier<BeltDirection> currentBeltDirectionNotifier = ValueNotifier(BeltDirection.right);
  final ValueNotifier<BeltDirection> currentOperatorDirectionNotifier = ValueNotifier(BeltDirection.right);

  // Callbacks for tracking placed items
  VoidCallback? onBeltPlaced;
  VoidCallback? onOperatorPlaced;
  VoidCallback? onExtractorPlaced;

  // Axis locking for belt placement
  int? _dragStartGridX;
  int? _dragStartGridY;

  // Getters for backward compatibility
  Tool get selectedTool => selectedToolNotifier.value;
  set selectedTool(Tool value) => selectedToolNotifier.value = value;

  BeltDirection get currentBeltDirection => currentBeltDirectionNotifier.value;
  set currentBeltDirection(BeltDirection value) => currentBeltDirectionNotifier.value = value;

  BeltDirection get currentOperatorDirection => currentOperatorDirectionNotifier.value;
  set currentOperatorDirection(BeltDirection value) => currentOperatorDirectionNotifier.value = value;

  InputManager({required this.tileManager});

  void handleKeyDown(LogicalKeyboardKey key) {
    pressedKeys.add(key);

    // Tool selection
    if (key == LogicalKeyboardKey.digit1) {
      selectedTool = Tool.none;
    } else if (key == LogicalKeyboardKey.digit2) {
      selectedTool = Tool.belt;
    } else if (key == LogicalKeyboardKey.digit3) {
      selectedTool = Tool.extractor;
    }
    // Belt direction rotation with R key
    else if (key == LogicalKeyboardKey.keyR) {
      rotateBeltDirection();
    }
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    pressedKeys.remove(key);
  }

  void rotateBeltDirection() {
    switch (currentBeltDirection) {
      case BeltDirection.right:
        currentBeltDirection = BeltDirection.down;
        break;
      case BeltDirection.down:
        currentBeltDirection = BeltDirection.left;
        break;
      case BeltDirection.left:
        currentBeltDirection = BeltDirection.up;
        break;
      case BeltDirection.up:
        currentBeltDirection = BeltDirection.right;
        break;
    }
  }

  void startDrag(int gridX, int gridY) {
    _dragStartGridX = gridX;
    _dragStartGridY = gridY;
  }

  void endDrag() {
    _dragStartGridX = null;
    _dragStartGridY = null;
  }

  void handleTap(int gridX, int gridY, {bool isRightClick = false}) {
    // Don't place tiles if panning or zooming
    if (pressedKeys.contains(LogicalKeyboardKey.space) ||
        pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.shiftRight)) {
      return;
    }

    // Apply axis locking for belt tool during drag
    int finalGridX = gridX;
    int finalGridY = gridY;

    if (!isRightClick && selectedTool == Tool.belt && _dragStartGridX != null && _dragStartGridY != null) {
      // For horizontal belts (left/right), lock Y coordinate
      if (currentBeltDirection == BeltDirection.left || currentBeltDirection == BeltDirection.right) {
        finalGridY = _dragStartGridY!;
      }
      // For vertical belts (up/down), lock X coordinate
      else {
        finalGridX = _dragStartGridX!;
      }
    }

    // Right click removes tiles (but not number tiles)
    if (isRightClick) {
      final existingTile = tileManager.getTile(finalGridX, finalGridY);
      // Only remove belt, extractor, and operator tiles, not number tiles
      if (existingTile.type == TileType.belt || existingTile.type == TileType.extractor) {
        tileManager.removeTile(finalGridX, finalGridY);
      } else if (existingTile.type == TileType.operator) {
        // Remove all 3 tiles of the operator
        _removeOperator(finalGridX, finalGridY, existingTile);
      }
      return;
    }

    // Check if there's already a tile here
    final existingTile = tileManager.getTile(finalGridX, finalGridY);

    // Place tile based on selected tool
    switch (selectedTool) {
      case Tool.none:
        break;
      case Tool.belt:
        // Can only place belt on empty tiles
        if (existingTile.type == TileType.empty) {
          tileManager.placeBelt(finalGridX, finalGridY, currentBeltDirection);
          onBeltPlaced?.call();
        }
        break;
      case Tool.extractor:
        // Can ONLY place extractor on number tiles (converts them to extractors)
        if (existingTile.type == TileType.number && existingTile.numberValue != null) {
          // Place extractor with the number value from the number tile
          tileManager.placeExtractor(finalGridX, finalGridY, extractValue: existingTile.numberValue!);
          onExtractorPlaced?.call();
        }
        break;
      case Tool.operatorAdd:
        // Can only place operator on empty tiles (and check 3-tile space)
        if (_canPlaceOperator(finalGridX, finalGridY)) {
          tileManager.placeOperator(finalGridX, finalGridY, OperatorType.add, currentOperatorDirection);
          onOperatorPlaced?.call();
        }
        break;
      case Tool.operatorSubtract:
        if (_canPlaceOperator(finalGridX, finalGridY)) {
          tileManager.placeOperator(finalGridX, finalGridY, OperatorType.subtract, currentOperatorDirection);
          onOperatorPlaced?.call();
        }
        break;
      case Tool.operatorMultiply:
        if (_canPlaceOperator(finalGridX, finalGridY)) {
          tileManager.placeOperator(finalGridX, finalGridY, OperatorType.multiply, currentOperatorDirection);
          onOperatorPlaced?.call();
        }
        break;
      case Tool.operatorDivide:
        if (_canPlaceOperator(finalGridX, finalGridY)) {
          tileManager.placeOperator(finalGridX, finalGridY, OperatorType.divide, currentOperatorDirection);
          onOperatorPlaced?.call();
        }
        break;
    }
  }

  void _removeOperator(int x, int y, Tile tile) {
    // If this is a reference tile, get the origin coordinates
    final int originX = tile.isOrigin ? x : (tile.originX ?? x);
    final int originY = tile.isOrigin ? y : (tile.originY ?? y);

    // Get the origin tile to determine orientation
    final originTile = tileManager.getTile(originX, originY);
    final bool isHorizontal = originTile.width == 3;

    // Remove all 3 tiles
    tileManager.removeTile(originX, originY); // Middle

    if (isHorizontal) {
      tileManager.removeTile(originX - 1, originY); // Left
      tileManager.removeTile(originX + 1, originY); // Right
    } else {
      tileManager.removeTile(originX, originY - 1); // Top
      tileManager.removeTile(originX, originY + 1); // Bottom
    }
  }

  bool _canPlaceOperator(int x, int y) {
    // Check if all 3 tiles (middle and sides) are empty
    final bool isHorizontal = currentOperatorDirection == BeltDirection.left ||
                              currentOperatorDirection == BeltDirection.right;

    // Check middle tile
    if (tileManager.getTile(x, y).type != TileType.empty) {
      return false;
    }

    if (isHorizontal) {
      // Check left and right tiles
      if (tileManager.getTile(x - 1, y).type != TileType.empty) return false;
      if (tileManager.getTile(x + 1, y).type != TileType.empty) return false;
    } else {
      // Check top and bottom tiles
      if (tileManager.getTile(x, y - 1).type != TileType.empty) return false;
      if (tileManager.getTile(x, y + 1).type != TileType.empty) return false;
    }

    return true;
  }

  bool get isPanning => pressedKeys.contains(LogicalKeyboardKey.space);

  bool get isZooming =>
      pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
      pressedKeys.contains(LogicalKeyboardKey.shiftRight);

  // Clean up notifiers
  void dispose() {
    selectedToolNotifier.dispose();
    currentBeltDirectionNotifier.dispose();
    currentOperatorDirectionNotifier.dispose();
  }
}
