import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multiplex/game/tool.dart';

import 'components/factory_component.dart';
import 'managers/input_manager.dart';
import 'managers/level_manager.dart';
import 'managers/render_manager.dart';
import 'managers/tile_manager.dart';
import 'models/tile.dart';

class Multiplex extends FlameGame
    with
        PanDetector,
        ScrollDetector,
        TapDetector,
        SecondaryTapDetector,
        KeyboardEvents {
  static const double baseTileSize = 64.0; // Base tile size
  double tileSize = baseTileSize; // Current tile size for the grid
  Vector2 gridOffset = Vector2.zero(); // Track the grid's position

  late final TileManager tileManager;
  late final RenderManager renderManager;
  late final InputManager inputManager;
  late final LevelManager levelManager;

  late final FactoryComponent factoryComponent;

  // Callback for when level changes (to update UI)
  VoidCallback? onLevelChanged;

  // Game Statistics
  int totalScore = 0;
  int tilesProcessed = 0;
  int beltsPlaced = 0;
  int operatorsPlaced = 0;
  int extractorsPlaced = 0;
  int levelsCompleted = 0;
  double totalPlaytime = 0.0; // in seconds
  int currentLevelBelts = 0;
  double currentLevelTime = 0.0;

  // Callbacks for stat updates
  VoidCallback? onStatsChanged;

  // Track dragging state
  bool _isDragging = false;
  bool _isRightClickDrag = false;
  Vector2? _lastDragGridPos;

  double _extractorSpawnTimer = 0.0;
  static const double extractorSpawnInterval = 1.0; // Spawn every 1 second

  double _beltMoveTimer = 0.0;
  static const double beltMoveInterval = 0.5; // Move every 0.5 seconds

  double _operatorProcessTimer = 0.0;
  static const double operatorProcessInterval = 0.5; // Process every 0.5 seconds

  Multiplex() {
    // Initialize managers in constructor so they're available immediately
    tileManager = TileManager();
    renderManager = RenderManager(
      tileManager: tileManager,
      getTileSize: () => tileSize,
      getGridOffset: () => gridOffset,
    );
    inputManager = InputManager(tileManager: tileManager);
    levelManager = LevelManager();

    // Set up input callbacks to track stats
    inputManager.onBeltPlaced = () {
      beltsPlaced++;
      currentLevelBelts++;
      onStatsChanged?.call();
    };
    inputManager.onOperatorPlaced = () {
      operatorsPlaced++;
      onStatsChanged?.call();
    };
    inputManager.onExtractorPlaced = () {
      extractorsPlaced++;
      onStatsChanged?.call();
    };
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.zoom = 1.0; // Default zoom level

    // Load levels from JSON
    await levelManager.loadLevels();

    // Initialize grid offset to center at (0, 0) if size is available
    if (size.x > 0 && size.y > 0) {
      gridOffset = Vector2(-size.x / 2, -size.y / 2);
    }

    // Get current level data
    final currentLevel = levelManager.currentLevel;
    final targetNumber = currentLevel?.targetNumber ?? 1;
    final targetValue = currentLevel?.targetValue ?? 10;
    final levelNumber = levelManager.currentLevelNumber;

    // Add factory component at (0, 0) as a 5x5 grid
    factoryComponent = FactoryComponent(
      position: Vector2.zero(),
      size: Vector2.all(baseTileSize * 5),
      targetNumber: targetNumber,
      targetValue: targetValue,
      currentValue: 0,
      level: levelNumber,
    );
    await add(factoryComponent);

    // Place factory tiles in tile manager at (0, 0)
    tileManager.placeFactory(-2, -2, 5, 5);

    // Spawn initial tiles from level
    _spawnInitialTiles();

    // Notify UI that initial level is loaded
    Future.microtask(() => onLevelChanged?.call());
  }

  void _spawnInitialTiles() {
    final currentLevel = levelManager.currentLevel;
    if (currentLevel == null) return;

    final random = Random();
    const minDistanceFromFactory = 10;
    const spawnRadius = 20; // Spawn within 20 tiles from factory

    for (final numberSpawn in currentLevel.numberSpawns) {
      int spawned = 0;
      int attempts = 0;
      const maxAttempts = 100;

      while (spawned < numberSpawn.count && attempts < maxAttempts) {
        attempts++;

        // Generate random position within spawn radius
        final x = random.nextInt(spawnRadius * 2 + 1) - spawnRadius;
        final y = random.nextInt(spawnRadius * 2 + 1) - spawnRadius;

        // Check if position is far enough from factory
        final distanceSquared = x * x + y * y;
        if (distanceSquared < minDistanceFromFactory * minDistanceFromFactory) {
          continue;
        }

        // Check if position is already occupied
        final existingTile = tileManager.getTile(x, y);
        if (existingTile.type != TileType.empty) {
          continue;
        }

        // Place the number tile
        tileManager.placeNumber(x, y, numberSpawn.value);
        spawned++;
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    // Dynamically set the viewport size to always match the widget size
    camera.viewport = FixedResolutionViewport(resolution: size);

    // Center the grid at (0, 0) by setting offset to negative viewport center
    // gridOffset represents the world position of the top-left corner of the viewport
    gridOffset = Vector2(
      -size.x / 2,
      -size.y / 2,
    );

    super.onGameResize(size);
  }

  // Convert grid coordinates to screen coordinates
  Vector2 gridToScreen(Vector2 gridPos) {
    return Vector2(
      gridPos.x * tileSize - gridOffset.x,
      gridPos.y * tileSize - gridOffset.y,
    );
  }

  // Convert screen coordinates to grid coordinates
  Vector2 screenToGrid(Vector2 screenPos) {
    return Vector2(
      ((screenPos.x + gridOffset.x) / tileSize).floor().toDouble(),
      ((screenPos.y + gridOffset.y) / tileSize).floor().toDouble(),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF90EE90).withValues(alpha: 0.5);

  @override
  void update(double dt) {
    super.update(dt);

    // Update playtime
    totalPlaytime += dt;
    currentLevelTime += dt;

    // Update factory position and size based on grid
    // Position at center of (0,0) tile since factory uses Anchor.center
    final centerOffset = Vector2.all(tileSize / 2);
    factoryComponent.position = gridToScreen(Vector2.zero()) + centerOffset;
    factoryComponent.size = Vector2.all(tileSize * 5);

    // Update extractor spawning timer
    _extractorSpawnTimer += dt;
    if (_extractorSpawnTimer >= extractorSpawnInterval) {
      _extractorSpawnTimer = 0.0;
      _spawnFromExtractors();
    }

    // Update belt movement timer
    _beltMoveTimer += dt;
    if (_beltMoveTimer >= beltMoveInterval) {
      _beltMoveTimer = 0.0;
      _moveBelts();
    }

    // Update operator processing timer
    _operatorProcessTimer += dt;
    if (_operatorProcessTimer >= operatorProcessInterval) {
      _operatorProcessTimer = 0.0;
      _processOperators();
    }
  }

  void _spawnFromExtractors() {
    // Find all extractor tiles - convert to list to avoid concurrent modification
    final extractors = tileManager.tiles.entries.where((entry) {
      return entry.value.type == TileType.extractor && entry.value.extractValue != null;
    }).toList();

    for (final extractorEntry in extractors) {
      final coords = extractorEntry.key.split(',');
      final extractorX = int.parse(coords[0]);
      final extractorY = int.parse(coords[1]);
      final extractValue = extractorEntry.value.extractValue!;

      // Try spawning in all 4 adjacent directions
      final adjacentPositions = [
        [extractorX, extractorY + 1, 'below'], // Below
        [extractorX, extractorY - 1, 'above'], // Above
        [extractorX + 1, extractorY, 'right'], // Right
        [extractorX - 1, extractorY, 'left'], // Left
      ];

      bool spawned = false;
      for (final pos in adjacentPositions) {
        final spawnX = pos[0] as int;
        final spawnY = pos[1] as int;
        final targetTile = tileManager.getTile(spawnX, spawnY);

        // Only spawn directly onto belts that aren't carrying anything
        if (targetTile.type == TileType.belt && targetTile.carryingNumber == null) {
          final updatedBelt = targetTile.copyWith(carryingNumber: extractValue);
          tileManager.setTile(spawnX, spawnY, updatedBelt);
          spawned = true;
          break; // Only spawn once per cycle
        }
      }
    }
  }

  void _moveBelts() {
    // Get all belt tiles
    final belts = tileManager.tiles.entries.where((entry) {
      return entry.value.type == TileType.belt;
    }).toList();

    // First pass: Pick up numbers from source tiles
    final pickupActions = <String, int>{};

    for (final beltEntry in belts) {
      final coords = beltEntry.key.split(',');
      final beltX = int.parse(coords[0]);
      final beltY = int.parse(coords[1]);
      final belt = beltEntry.value;

      // Skip if already carrying something
      if (belt.carryingNumber != null) continue;
      if (belt.beltDirection == null) continue;

      // Get source position (opposite of belt direction)
      final sourceOffset = _getOppositeDirectionOffset(belt.beltDirection!);
      final sourceX = beltX + sourceOffset[0];
      final sourceY = beltY + sourceOffset[1];

      final sourceTile = tileManager.getTile(sourceX, sourceY);

      // Can pick up from belts carrying numbers OR operator outputs (origin tiles with carryingNumber)
      if (sourceTile.type == TileType.belt && sourceTile.carryingNumber != null) {
        pickupActions[beltEntry.key] = sourceTile.carryingNumber!;
      } else if (sourceTile.type == TileType.operator && sourceTile.isOrigin && sourceTile.carryingNumber != null) {
        // Pick up from operator output (middle tile)
        pickupActions[beltEntry.key] = sourceTile.carryingNumber!;
      }
    }

    // Apply pickups
    for (final entry in pickupActions.entries) {
      final coords = entry.key.split(',');
      final beltX = int.parse(coords[0]);
      final beltY = int.parse(coords[1]);
      final belt = tileManager.getTile(beltX, beltY);

      // Get source position to clear carrying number
      final sourceOffset = _getOppositeDirectionOffset(belt.beltDirection!);
      final sourceX = beltX + sourceOffset[0];
      final sourceY = beltY + sourceOffset[1];
      final sourceTile = tileManager.getTile(sourceX, sourceY);

      // Clear carrying number from source (belt or operator output)
      if (sourceTile.type == TileType.belt) {
        final clearedBelt = sourceTile.copyWith(clearCarrying: true);
        tileManager.setTile(sourceX, sourceY, clearedBelt);
      } else if (sourceTile.type == TileType.operator && sourceTile.isOrigin) {
        // Clear output from operator
        final clearedOperator = sourceTile.copyWith(clearCarrying: true);
        tileManager.setTile(sourceX, sourceY, clearedOperator);
      }

      // Set carrying number on current belt
      final updatedBelt = belt.copyWith(carryingNumber: entry.value);
      tileManager.setTile(beltX, beltY, updatedBelt);
    }

    // Second pass: Move numbers forward
    final moveActions = <String, int?>{};

    for (final beltEntry in belts) {
      final coords = beltEntry.key.split(',');
      final beltX = int.parse(coords[0]);
      final beltY = int.parse(coords[1]);
      final belt = beltEntry.value;

      if (belt.carryingNumber == null) continue;
      if (belt.beltDirection == null) continue;

      // Get destination position (belt direction)
      final destOffset = _getDirectionOffset(belt.beltDirection!);
      final destX = beltX + destOffset[0];
      final destY = beltY + destOffset[1];

      final destTile = tileManager.getTile(destX, destY);

      // Can move to belts, factory, or operator inputs
      if (destTile.type == TileType.belt && destTile.carryingNumber == null) {
        // Transfer to next belt
        final updatedDestBelt = destTile.copyWith(carryingNumber: belt.carryingNumber);
        tileManager.setTile(destX, destY, updatedDestBelt);
        moveActions[beltEntry.key] = null; // Clear carrier
      } else if (destTile.type == TileType.factory) {
        // Deliver to factory
        _deliverToFactory(belt.carryingNumber!);
        moveActions[beltEntry.key] = null; // Clear carrier
      } else if (destTile.type == TileType.operator && !destTile.isOrigin && destTile.carryingNumber == null) {
        // Deliver to operator input tile (not the origin/middle tile)
        final updatedInput = destTile.copyWith(carryingNumber: belt.carryingNumber);
        tileManager.setTile(destX, destY, updatedInput);
        moveActions[beltEntry.key] = null; // Clear carrier
      }
      // If destination is empty or occupied, keep carrying the number
    }

    // Apply moves (clear carrying numbers)
    for (final entry in moveActions.entries) {
      final coords = entry.key.split(',');
      final beltX = int.parse(coords[0]);
      final beltY = int.parse(coords[1]);
      final belt = tileManager.getTile(beltX, beltY);

      final updatedBelt = belt.copyWith(clearCarrying: true);
      tileManager.setTile(beltX, beltY, updatedBelt);
    }
  }

  List<int> _getDirectionOffset(BeltDirection direction) {
    switch (direction) {
      case BeltDirection.up:
        return [0, -1];
      case BeltDirection.down:
        return [0, 1];
      case BeltDirection.left:
        return [-1, 0];
      case BeltDirection.right:
        return [1, 0];
    }
  }

  List<int> _getOppositeDirectionOffset(BeltDirection direction) {
    switch (direction) {
      case BeltDirection.up:
        return [0, 1]; // Opposite of up is down
      case BeltDirection.down:
        return [0, -1]; // Opposite of down is up
      case BeltDirection.left:
        return [1, 0]; // Opposite of left is right
      case BeltDirection.right:
        return [-1, 0]; // Opposite of right is left
    }
  }

  void _processOperators() {
    // Find all operator origin tiles
    final operators = tileManager.tiles.entries.where((entry) {
      return entry.value.type == TileType.operator &&
             entry.value.isOrigin &&
             entry.value.operatorType != null;
    }).toList();

    for (final operatorEntry in operators) {
      final coords = operatorEntry.key.split(',');
      final operatorX = int.parse(coords[0]);
      final operatorY = int.parse(coords[1]);
      final operator = operatorEntry.value;
      final isHorizontal = operator.width == 3;

      // Get input tile positions
      int input1X, input1Y, input2X, input2Y;
      if (isHorizontal) {
        // Horizontal: left and right inputs
        input1X = operatorX - 1; input1Y = operatorY; // Left
        input2X = operatorX + 1; input2Y = operatorY; // Right
      } else {
        // Vertical: top and bottom inputs
        input1X = operatorX; input1Y = operatorY - 1; // Top
        input2X = operatorX; input2Y = operatorY + 1; // Bottom
      }

      // Check if both inputs have numbers from belts
      final input1Tile = tileManager.getTile(input1X, input1Y);
      final input2Tile = tileManager.getTile(input2X, input2Y);

      // Inputs can be belts carrying numbers OR the operator input tiles themselves carrying numbers
      final int? num1 = input1Tile.carryingNumber;
      final int? num2 = input2Tile.carryingNumber;

      if (num1 != null && num2 != null) {
        // Perform the operation
        int? result;
        switch (operator.operatorType!) {
          case OperatorType.add:
            result = num1 + num2;
            break;
          case OperatorType.subtract:
            result = num1 - num2;
            break;
          case OperatorType.multiply:
            result = num1 * num2;
            break;
          case OperatorType.divide:
            if (num2 != 0) {
              result = num1 ~/ num2; // Integer division
            }
            break;
        }

        if (result != null) {

          // Clear inputs
          if (input1Tile.type == TileType.belt) {
            tileManager.setTile(input1X, input1Y, input1Tile.copyWith(clearCarrying: true));
          } else if (input1Tile.type == TileType.operator) {
            tileManager.setTile(input1X, input1Y, input1Tile.copyWith(clearCarrying: true));
          }

          if (input2Tile.type == TileType.belt) {
            tileManager.setTile(input2X, input2Y, input2Tile.copyWith(clearCarrying: true));
          } else if (input2Tile.type == TileType.operator) {
            tileManager.setTile(input2X, input2Y, input2Tile.copyWith(clearCarrying: true));
          }

          // Store result on the operator origin tile
          final updatedOperator = operator.copyWith(carryingNumber: result);
          tileManager.setTile(operatorX, operatorY, updatedOperator);
        }
      }
    }
  }

  String _getOperatorSymbol(OperatorType type) {
    switch (type) {
      case OperatorType.add: return '+';
      case OperatorType.subtract: return '-';
      case OperatorType.multiply: return '×';
      case OperatorType.divide: return '÷';
    }
  }

  void _deliverToFactory(int value) {
    // Only count if the delivered number matches the target number
    if (value == factoryComponent.targetNumber) {
      factoryComponent.currentValue++;

      // Update stats - tile processed and score
      tilesProcessed++;
      totalScore += 10 * levelManager.currentLevelNumber; // Score increases with level
      onStatsChanged?.call();

      // Update factory origin tile in tile manager
      final factoryTile = tileManager.getTile(0, 0);
      if (factoryTile.type == TileType.factory && factoryTile.isOrigin) {
        final updatedFactory = Tile(
          type: TileType.factory,
          color: factoryTile.color,
          isOrigin: true,
          width: 5,
          height: 5,
          targetNumber: factoryTile.targetNumber,
          currentValue: factoryComponent.currentValue,
          level: factoryTile.level,
        );
        tileManager.setTile(0, 0, updatedFactory);
      }

      // Check if level completed
      _completeLevel();
    }
    // If wrong number delivered, it's just ignored/consumed
  }

  void _completeLevel() {
    if (factoryComponent.currentValue >= factoryComponent.targetValue) {
      // Update stats for level completion
      levelsCompleted++;

      // Bonus points for completing level
      int levelBonus = 100 * levelManager.currentLevelNumber;

      // Speed bonus if completed quickly (under 2 minutes)
      if (currentLevelTime < 120) {
        levelBonus += 500;
      }

      // Efficiency bonus if used few belts (under 15)
      if (currentLevelBelts < 15) {
        levelBonus += 250;
      }

      totalScore += levelBonus;
      onStatsChanged?.call();

      levelManager.nextLevel();
      _loadLevel();
    }
  }

  void _loadLevel() {
    final currentLevel = levelManager.currentLevel;
    if (currentLevel == null) return;

    // Clear all tiles
    tileManager.tiles.clear();

    // Reset level-specific stats
    currentLevelBelts = 0;
    currentLevelTime = 0.0;

    // Reset factory
    final targetNumber = currentLevel.targetNumber;
    final targetValue = currentLevel.targetValue;
    final levelNumber = levelManager.currentLevelNumber;

    factoryComponent.targetNumber = targetNumber;
    factoryComponent.targetValue = targetValue;
    factoryComponent.currentValue = 0;
    factoryComponent.level = levelNumber;

    // Place factory back at (0, 0)
    tileManager.placeFactory(-2, -2, 5, 5);

    // Respawn initial tiles
    _spawnInitialTiles();

    // Notify UI that level changed
    onLevelChanged?.call();
  }

  @override
  void render(Canvas canvas) {
    final visibleRect = camera.viewport.size.toRect();

    // Draw grid first
    renderManager.drawInfiniteGrid(canvas, visibleRect);

    // Draw tiles
    renderManager.drawTiles(canvas, visibleRect);

    // Draw coordinates on top so they're always visible
    renderManager.drawCellCoordinates(canvas, visibleRect, baseTileSize);

    // Then draw factory component on top (covers grid)
    super.render(canvas);
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      inputManager.handleKeyDown(event.logicalKey);
    } else if (event is KeyUpEvent) {
      inputManager.handleKeyUp(event.logicalKey);
    }
    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    _isRightClickDrag = false; // Left button

    // Use widget position (relative to game widget) instead of global (includes title bar)
    final screenPos = info.eventPosition.widget;
    final gridPos = screenToGrid(screenPos);
    final gridX = gridPos.x.toInt();
    final gridY = gridPos.y.toInt();

    // Single tap placement - only if tool is selected and not panning/zooming
    if (!inputManager.isPanning && !inputManager.isZooming && inputManager.selectedTool != Tool.none) {
      inputManager.handleTap(gridX, gridY);
    }
  }

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    super.onSecondaryTapDown(info);
    _isRightClickDrag = true; // Right button

    // Single right-click removal - always allowed
    if (!inputManager.isPanning && !inputManager.isZooming) {
      // Use widget position instead of global to account for title bar
      final gridPos = screenToGrid(info.eventPosition.widget);
      final gridX = gridPos.x.toInt();
      final gridY = gridPos.y.toInt();
      inputManager.handleTap(gridX, gridY, isRightClick: true);
    }
  }

  @override
  void onPanStart(DragStartInfo info) {
    super.onPanStart(info);

    // Start dragging if not panning/zooming
    // For placement: only if a tool is selected
    // For removal: always allow right-click drag
    if (!inputManager.isPanning && !inputManager.isZooming) {
      if (_isRightClickDrag || inputManager.selectedTool != Tool.none) {
        _isDragging = true;

        // Use widget position instead of global to account for title bar
        final gridPos = screenToGrid(info.eventPosition.widget);
        final gridX = gridPos.x.toInt();
        final gridY = gridPos.y.toInt();
        _lastDragGridPos = Vector2(gridX.toDouble(), gridY.toDouble());

        // Place/remove tile at start position
        inputManager.handleTap(gridX, gridY, isRightClick: _isRightClickDrag);
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    super.onPanEnd(info);
    _isDragging = false;
    _isRightClickDrag = false;
    _lastDragGridPos = null;
  }

  @override
  void onPanCancel() {
    super.onPanCancel();
    _isDragging = false;
    _isRightClickDrag = false;
    _lastDragGridPos = null;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (inputManager.isZooming) {
      // Zooming with Shift + Drag
      final delta = info.delta.global;
      if (delta.y > 0) {
        _updateTileSize(-0.01); // Zoom out
      } else if (delta.y < 0) {
        _updateTileSize(0.01); // Zoom in
      }
    } else if (inputManager.isPanning) {
      // Panning with Space + Drag
      gridOffset -= info.delta.global;
    } else if (_isDragging) {
      // Continuous tile placement/removal while dragging
      // Use widget position instead of global to account for title bar
      final gridPos = screenToGrid(info.eventPosition.widget);
      final gridX = gridPos.x.toInt();
      final gridY = gridPos.y.toInt();

      // Only place/remove if we moved to a different grid cell
      if (_lastDragGridPos == null ||
          _lastDragGridPos!.x.toInt() != gridX ||
          _lastDragGridPos!.y.toInt() != gridY) {

        _lastDragGridPos = Vector2(gridX.toDouble(), gridY.toDouble());
        inputManager.handleTap(gridX, gridY, isRightClick: _isRightClickDrag);
      }
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // Ensure scrolling doesn't trigger tile placement
    _isDragging = false;
    _lastDragGridPos = null;

    // Use scroll for zooming only
    final double scrollDelta = info.scrollDelta.global.y;
    if (scrollDelta > 0) {
      _updateTileSize(-0.05); // Zoom out
    } else if (scrollDelta < 0) {
      _updateTileSize(0.05); // Zoom in
    }
  }

  void zoomIn() {
    _updateTileSize(0.1); // Increase tile size
  }

  void zoomOut() {
    _updateTileSize(-0.1); // Decrease tile size
  }

  void _updateTileSize(double delta) {
    tileSize = (tileSize + delta * baseTileSize)
        .clamp(baseTileSize / 2, baseTileSize * 2);
  }

  /// Export current game state for saving/persistence
  Map<String, dynamic> exportState() {
    return {
      'currentLevel': levelManager.currentLevelNumber,
      'totalScore': totalScore,
      'tilesProcessed': tilesProcessed,
      'beltsPlaced': beltsPlaced,
      'operatorsPlaced': operatorsPlaced,
      'extractorsPlaced': extractorsPlaced,
      'levelsCompleted': levelsCompleted,
      'totalPlaytimeSeconds': totalPlaytime.toInt(),
      'lastPlayed': DateTime.now().toIso8601String(),
    };
  }

  /// Import and restore game state from saved data
  void importState(Map<String, dynamic> state) {
    totalScore = state['totalScore'] ?? 0;
    tilesProcessed = state['tilesProcessed'] ?? 0;
    beltsPlaced = state['beltsPlaced'] ?? 0;
    operatorsPlaced = state['operatorsPlaced'] ?? 0;
    extractorsPlaced = state['extractorsPlaced'] ?? 0;
    levelsCompleted = state['levelsCompleted'] ?? 0;
    totalPlaytime = (state['totalPlaytimeSeconds'] ?? 0).toDouble();

    // Restore level and load it
    final targetLevel = state['currentLevel'] ?? 1;
    if (targetLevel > levelManager.currentLevelNumber) {
      while (levelManager.currentLevelNumber < targetLevel &&
             levelManager.currentLevelNumber < levelManager.totalLevels) {
        levelManager.nextLevel();
      }
    }
    _loadLevel();
    onStatsChanged?.call();
    onLevelChanged?.call();
  }
}
