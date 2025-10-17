import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multiplex/game/tool.dart';

import 'components/factory_component.dart';
import 'managers/camera_manager.dart';
import 'managers/input_manager.dart';
import 'managers/level_manager.dart';
import 'managers/render_manager.dart';
import 'managers/simulation_manager.dart';
import 'managers/tile_manager.dart';
import 'models/tile.dart';

class Multiplex extends FlameGame
    with
        PanDetector,
        TapDetector,
        SecondaryTapDetector,
        KeyboardEvents {
  static const double baseTileSize = 64.0; // Base tile size

  // Managers
  late final TileManager tileManager;
  late final RenderManager renderManager;
  late final InputManager inputManager;
  late final LevelManager levelManager;
  late final CameraManager cameraManager;
  late final SimulationManager simulationManager;

  // Delegate camera properties
  double get tileSize => cameraManager.tileSize;
  set tileSize(double value) => cameraManager.tileSize = value;

  Vector2 get gridOffset => cameraManager.gridOffset;
  set gridOffset(Vector2 value) => cameraManager.gridOffset = value;

  late final FactoryComponent factoryComponent;

  // Callback for when level changes (to update UI)
  VoidCallback? onLevelChanged;

  // Callback for when level is completed (to save progress)
  VoidCallback? onLevelCompleted;

  // Callback to check if right-click is being held during drag
  bool Function()? isRightClickPressed;

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

  // Progress data to load after game initializes
  Map<String, dynamic>? _pendingProgressData;

  // Track dragging state
  bool _isRightClickDrag = false;

  Multiplex() {
    // Initialize managers in constructor so they're available immediately
    tileManager = TileManager();
    cameraManager = CameraManager();
    simulationManager = SimulationManager(tileManager: tileManager);

    renderManager = RenderManager(
      tileManager: tileManager,
      getTileSize: () => tileSize,
      getGridOffset: () => gridOffset,
    );
    inputManager = InputManager(tileManager: tileManager);
    levelManager = LevelManager();

    // Set up simulation callback for factory delivery
    simulationManager.onFactoryDelivery = (value) => _deliverToFactory(value);

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

    // Initialize camera's grid offset to center at (0, 0) if size is available
    cameraManager.initializeGridOffset(size);

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

    // Load pending progress data if available
    if (_pendingProgressData != null) {
      importState(_pendingProgressData!);
      _pendingProgressData = null; // Clear after loading
    }

    // Notify UI that initial level is loaded
    Future.microtask(() => onLevelChanged?.call());
  }

  /// Set progress data to be loaded when the game initializes
  void setPendingProgress(Map<String, dynamic> progressData) {
    _pendingProgressData = progressData;
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

    // Update grid offset via camera manager
    cameraManager.updateGridOffset(size);

    super.onGameResize(size);
  }

  // Convert grid coordinates to screen coordinates
  Vector2 gridToScreen(Vector2 gridPos) {
    return cameraManager.gridToScreen(gridPos);
  }

  // Convert screen coordinates to grid coordinates
  Vector2 screenToGrid(Vector2 screenPos) {
    return cameraManager.screenToGrid(screenPos);
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
    factoryComponent.position = cameraManager.gridToScreen(Vector2.zero()) + centerOffset;
    factoryComponent.size = Vector2.all(tileSize * 5);

    // Update simulation (handles belts, operators, extractors)
    simulationManager.update(dt);
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

      // Advance to next level BEFORE saving
      levelManager.nextLevel();

      // Notify that level is completed (triggers save with updated level number)
      onLevelCompleted?.call();

      // Load the new level
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

    // ONLY handle pan events when Space/Shift is pressed (for camera panning/zooming)
    // This prevents Magic Mouse gestures from triggering pan events
    if (!inputManager.isPanning && !inputManager.isZooming) {
      return; // Ignore all pan events unless explicitly panning/zooming
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    super.onPanEnd(info);
    _isRightClickDrag = false;
  }

  @override
  void onPanCancel() {
    super.onPanCancel();
    _isRightClickDrag = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // ONLY handle pan updates when Space/Shift is pressed
    // This prevents Magic Mouse gestures from being processed as pan events
    if (!inputManager.isPanning && !inputManager.isZooming) {
      return; // Ignore all pan updates unless explicitly panning/zooming
    }

    if (inputManager.isZooming) {
      // Zooming with Shift + Drag
      final delta = info.delta.global;
      if (delta.y > 0) {
        cameraManager.zoom(-0.01); // Zoom out
      } else if (delta.y < 0) {
        cameraManager.zoom(0.01); // Zoom in
      }
    } else if (inputManager.isPanning) {
      // Panning with Space + Drag
      cameraManager.pan(info.delta.global);
    }
  }


  void zoomIn() {
    cameraManager.zoomIn();
  }

  void zoomOut() {
    cameraManager.zoomOut();
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

    // Set the level directly using the new setLevel method
    levelManager.setLevel(targetLevel);

    // Load the level
    _loadLevel();

    onStatsChanged?.call();
    onLevelChanged?.call();
  }
}
