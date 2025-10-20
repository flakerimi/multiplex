import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/game_screen_controller.dart';
import '../game/models/tile.dart';
import '../game/multiplex.dart';
import '../game/tool.dart';
import '../game/ui/custom_cursor.dart';
import '../game/ui/sidebar.dart';
import '../services/notification_service.dart';

class GameScreen extends StatelessWidget {
  final Multiplex game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Get or create controllers
    final screenController = Get.put(
      GameScreenController(game: game),
      tag: game.hashCode.toString(),
    );
    final gameController = Get.put(GameController());
    final authController = Get.find<AuthController>();
    final notificationService = NotificationService();

    // Initialize on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame(context, gameController, notificationService, screenController);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context, gameController, screenController);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop(context, gameController, screenController);
              if (shouldPop) {
                Get.back();
              }
            },
          ),
          title: Obx(() {
            final user = authController.currentUser.value;
            final displayName = user != null ? user.fullName : 'Player';
            return Text('Multiplex - $displayName');
          }),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Progress',
              onPressed: () => _saveProgress(gameController, screenController),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () {
                Get.toNamed('/profile');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout?'),
                    content: const Text(
                      'Are you sure you want to logout? Make sure to save your progress first.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await authController.logout();
                }
              },
            ),
          ],
        ),
        body: ValueListenableBuilder<Tool>(
          valueListenable: game.inputManager.selectedToolNotifier,
          builder: (context, selectedTool, child) {
            return Listener(
              behavior: HitTestBehavior.translucent, // Don't consume events
              onPointerDown: (event) {
                final tileSize = game.tileSize;
                final gridOffset = game.gridOffset;
                final gridX = ((event.localPosition.dx + gridOffset.x) / tileSize).floor();
                final gridY = ((event.localPosition.dy + gridOffset.y) / tileSize).floor();

                // Right button = 2 in the buttons bitmask
                if ((event.buttons & 2) != 0) {
                  screenController.isRightClickDragging.value = true;

                  // Start tracking last position
                  screenController.lastRightClickGridPos.value = Offset(gridX.toDouble(), gridY.toDouble());

                  // Remove tile at start position
                  game.inputManager.handleTap(gridX, gridY, isRightClick: true);
                }
                // Left button = 1 in the buttons bitmask
                else if ((event.buttons & 1) != 0 && selectedTool == Tool.belt) {
                  screenController.isLeftClickDragging.value = true;

                  // Start drag for axis locking and direction detection
                  game.inputManager.startDrag(gridX, gridY);

                  // Clear preview and add start position
                  screenController.beltPreviewPositions.clear();
                  screenController.beltPreviewPositions.add(Offset(gridX.toDouble(), gridY.toDouble()));
                  screenController.beltPreviewDirection.value = null;
                  screenController.lastLeftClickGridPos.value = null;

                  // Don't place belts yet - only show preview
                }
              },
              onPointerMove: (event) {
                // Update cursor position during drag (hover events don't fire during drag)
                screenController.updateMousePosition(event.localPosition);

                final tileSize = game.tileSize;
                final gridOffset = game.gridOffset;
                final gridX = ((event.localPosition.dx + gridOffset.x) / tileSize).floor();
                final gridY = ((event.localPosition.dy + gridOffset.y) / tileSize).floor();

                // Handle right-click drag manually (Flame's PanDetector doesn't support it)
                if ((event.buttons & 2) != 0) {
                  if (!screenController.isRightClickDragging.value) {
                    screenController.isRightClickDragging.value = true;
                  }

                  // Only remove if we moved to a different grid cell
                  final lastPos = screenController.lastRightClickGridPos.value;
                  if (lastPos == null || lastPos.dx.toInt() != gridX || lastPos.dy.toInt() != gridY) {
                    screenController.lastRightClickGridPos.value = Offset(gridX.toDouble(), gridY.toDouble());
                    game.inputManager.handleTap(gridX, gridY, isRightClick: true);
                  }
                }
                // Handle left-click drag for belt preview
                else if ((event.buttons & 1) != 0 && selectedTool == Tool.belt) {
                  if (!screenController.isLeftClickDragging.value) {
                    screenController.isLeftClickDragging.value = true;
                    game.inputManager.startDrag(gridX, gridY);
                  }

                  final startX = game.inputManager.dragStartGridX!;
                  final startY = game.inputManager.dragStartGridY!;
                  final dx = gridX - startX;
                  final dy = gridY - startY;

                  // Detect direction based on current position relative to start
                  // Determine if movement is more horizontal or vertical
                  bool isHorizontal = screenController.beltPreviewDirection.value == BeltDirection.left ||
                                      screenController.beltPreviewDirection.value == BeltDirection.right;

                  // On first movement, detect axis (horizontal vs vertical)
                  if (screenController.beltPreviewDirection.value == null && (dx.abs() > 0 || dy.abs() > 0)) {
                    isHorizontal = dx.abs() > dy.abs();
                  }

                  // Update direction based on current position relative to start
                  if (dx.abs() > 0 || dy.abs() > 0) {
                    BeltDirection detectedDirection;
                    if (isHorizontal) {
                      // Horizontal movement - direction based on which side of start we are
                      detectedDirection = dx >= 0 ? BeltDirection.right : BeltDirection.left;
                    } else {
                      // Vertical movement - direction based on which side of start we are
                      detectedDirection = dy >= 0 ? BeltDirection.down : BeltDirection.up;
                    }
                    screenController.beltPreviewDirection.value = detectedDirection;
                  }

                  // Lock to axis based on detected direction
                  int lockedGridX = gridX;
                  int lockedGridY = gridY;

                  if (screenController.beltPreviewDirection.value != null) {
                    final direction = screenController.beltPreviewDirection.value!;

                    // Lock to the appropriate axis based on direction
                    if (direction == BeltDirection.left || direction == BeltDirection.right) {
                      lockedGridY = startY; // Lock Y axis for horizontal movement
                    } else {
                      lockedGridX = startX; // Lock X axis for vertical movement
                    }

                    // Clear and rebuild preview from start to current position
                    screenController.beltPreviewPositions.clear();

                    // Fill from start to current position
                    if (direction == BeltDirection.left || direction == BeltDirection.right) {
                      // Horizontal: fill from startX to lockedGridX at startY
                      final minX = startX < lockedGridX ? startX : lockedGridX;
                      final maxX = startX > lockedGridX ? startX : lockedGridX;
                      for (int x = minX; x <= maxX; x++) {
                        screenController.beltPreviewPositions.add(Offset(x.toDouble(), startY.toDouble()));
                      }
                    } else {
                      // Vertical: fill from startY to lockedGridY at startX
                      final minY = startY < lockedGridY ? startY : lockedGridY;
                      final maxY = startY > lockedGridY ? startY : lockedGridY;
                      for (int y = minY; y <= maxY; y++) {
                        screenController.beltPreviewPositions.add(Offset(startX.toDouble(), y.toDouble()));
                      }
                    }

                    screenController.lastLeftClickGridPos.value = Offset(lockedGridX.toDouble(), lockedGridY.toDouble());
                  }
                }
              },
              onPointerUp: (event) {
                // Place all preview belts with correct direction
                if (screenController.isLeftClickDragging.value &&
                    selectedTool == Tool.belt &&
                    screenController.beltPreviewPositions.isNotEmpty) {
                  final direction = screenController.beltPreviewDirection.value;

                  // Place all belts at once with the detected direction
                  for (final pos in screenController.beltPreviewPositions) {
                    game.inputManager.handleTap(
                      pos.dx.toInt(),
                      pos.dy.toInt(),
                      overrideDirection: direction,
                    );
                  }

                  // Clear preview
                  screenController.beltPreviewPositions.clear();
                  screenController.beltPreviewDirection.value = null;
                }

                screenController.isRightClickDragging.value = false;
                screenController.lastRightClickGridPos.value = null;
                screenController.isLeftClickDragging.value = false;
                screenController.lastLeftClickGridPos.value = null;
                game.inputManager.endDrag();
              },
              onPointerCancel: (event) {
                // Clear preview on cancel
                screenController.beltPreviewPositions.clear();
                screenController.beltPreviewDirection.value = null;

                screenController.isRightClickDragging.value = false;
                screenController.lastRightClickGridPos.value = null;
                screenController.isLeftClickDragging.value = false;
                screenController.lastLeftClickGridPos.value = null;
                game.inputManager.endDrag();
              },
              child: MouseRegion(
                cursor: selectedTool == Tool.none ? SystemMouseCursors.basic : SystemMouseCursors.none,
                onHover: (event) {
                  screenController.updateMousePosition(event.localPosition);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          GameWidget(game: game),
                        // Belt preview overlay
                        Obx(() {
                          if (screenController.beltPreviewPositions.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return CustomPaint(
                            size: Size.infinite,
                            painter: BeltPreviewPainter(
                              previewPositions: screenController.beltPreviewPositions,
                              tileSize: game.tileSize,
                              gridOffset: game.gridOffset,
                            ),
                          );
                        }),
                        // Custom cursor overlay - only show over game area
                        ValueListenableBuilder<BeltDirection>(
                          valueListenable: game.inputManager.currentBeltDirectionNotifier,
                          builder: (context, beltDirection, child) {
                            return ValueListenableBuilder<BeltDirection>(
                              valueListenable: game.inputManager.currentOperatorDirectionNotifier,
                              builder: (context, operatorDirection, child) {
                                return Obx(() => CustomCursor(
                                  position: screenController.mousePosition.value,
                                  selectedTool: selectedTool,
                                  beltDirection: beltDirection,
                                  operatorDirection: operatorDirection,
                                  size: game.tileSize,
                                ));
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Use ValueListenableBuilder to reactively update sidebar when state changes
                  ValueListenableBuilder<BeltDirection>(
                    valueListenable: game.inputManager.currentBeltDirectionNotifier,
                    builder: (context, beltDirection, child) {
                      return ValueListenableBuilder<BeltDirection>(
                        valueListenable: game.inputManager.currentOperatorDirectionNotifier,
                        builder: (context, operatorDirection, child) {
                          return Sidebar(
                            selectedTool: selectedTool,
                            beltDirection: beltDirection,
                            operatorDirection: operatorDirection,
                            unlockedOperators: game.levelManager.currentLevel?.unlockedOperators ?? [],
                            onToolSelected: (tool) {
                              game.inputManager.selectedTool = tool;
                            },
                            onRotateBelt: () {
                              if (selectedTool == Tool.belt) {
                                game.inputManager.rotateBeltDirection();
                              } else if (_isOperatorTool(selectedTool)) {
                                game.inputManager.rotateOperatorDirection();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            );
          },
        ),
      ),
    );
  }

  /// Initialize achievements and game state
  Future<void> _initializeGame(
    BuildContext context,
    GameController gameController,
    NotificationService notificationService,
    GameScreenController screenController,
  ) async {
    try {
      // Get progress data from route arguments
      final args = Get.arguments as Map<String, dynamic>?;
      debugPrint('[GameScreen] Route arguments: $args');
      final progressData = args?['progress'] as Map<String, dynamic>?;
      debugPrint('[GameScreen] Progress data: $progressData');

      // Set pending progress data to be loaded when game initializes
      if (progressData != null) {
        game.setPendingProgress(progressData);
      }

      // Set up callback to mark unsaved changes when level changes
      game.onLevelChanged = () {
        screenController.hasUnsavedChanges.value = true;
        _syncGameStatsToController(gameController);
      };

      // Set up callback when stats change in the game
      game.onStatsChanged = () {
        _syncGameStatsToController(gameController);
      };

      // Set up callback to auto-save when level is completed
      game.onLevelCompleted = () {
        debugPrint('Level completed! Auto-saving progress...');
        _saveProgress(gameController, screenController);
      };

      // Set up callback for right-click detection
      game.isRightClickPressed = () => screenController.isRightClickDragging.value;

      // Initialize notification service
      notificationService.initialize(context);

      // Initialize achievements
      await gameController.initializeAchievements();

      // Sync initial game state (progress is loaded automatically by game.onLoad())
      _syncGameStatsToController(gameController);

      // Sync stats to API on initial load
      await gameController.syncStatsToAPI();

      // Start auto-save
      gameController.startAutoSave();
    } catch (e) {
      debugPrint('Error initializing game: $e');
    }
  }

  /// Sync game stats from Multiplex to GameController
  void _syncGameStatsToController(GameController gameController) {
    gameController.updateStatsAndCheck(
      currentLevel: game.levelManager.currentLevelNumber,
      totalScore: game.totalScore,
      tilesProcessed: game.tilesProcessed,
      beltsPlaced: game.beltsPlaced,
      operatorsPlaced: game.operatorsPlaced,
      extractorsPlaced: game.extractorsPlaced,
      levelsCompleted: game.levelsCompleted,
      totalPlaytimeSeconds: game.totalPlaytime.toInt(),
    );
  }

  Future<bool> _onWillPop(
    BuildContext context,
    GameController gameController,
    GameScreenController screenController,
  ) async {
    if (!screenController.hasUnsavedChanges.value) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text(
          'You have unsaved progress. Do you want to save before exiting?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Exit without saving
              Navigator.of(context).pop(true);
            },
            child: const Text('Exit Without Saving'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save and exit
              await _saveProgress(gameController, screenController);
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveProgress(
    GameController gameController,
    GameScreenController screenController,
  ) async {
    try {
      // Sync stats to controller first
      _syncGameStatsToController(gameController);

      // Save progress via controller
      final success = await gameController.saveProgress();

      // Also sync stats to API
      await gameController.syncStatsToAPI();

      if (success) {
        screenController.hasUnsavedChanges.value = false;
      }
    } catch (e) {
      debugPrint('Error saving progress: $e');
      Get.snackbar(
        'Save Error',
        'Failed to save progress: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool _isOperatorTool(Tool tool) {
    return tool == Tool.operatorAdd ||
           tool == Tool.operatorSubtract ||
           tool == Tool.operatorMultiply ||
           tool == Tool.operatorDivide;
  }
}

/// Custom painter for belt preview overlay during drag
class BeltPreviewPainter extends CustomPainter {
  final List<Offset> previewPositions;
  final double tileSize;
  final Vector2 gridOffset;

  BeltPreviewPainter({
    required this.previewPositions,
    required this.tileSize,
    required this.gridOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewPositions.isEmpty) return;

    // Semi-transparent blue for preview tiles
    final paint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Border paint for preview tiles
    final borderPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final gridPos in previewPositions) {
      // Convert grid position to screen position
      final screenX = gridPos.dx * tileSize - gridOffset.x;
      final screenY = gridPos.dy * tileSize - gridOffset.y;

      final rect = Rect.fromLTWH(screenX, screenY, tileSize, tileSize);

      // Draw filled rectangle
      canvas.drawRect(rect, paint);

      // Draw border
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(BeltPreviewPainter oldDelegate) {
    return previewPositions != oldDelegate.previewPositions;
  }
}
