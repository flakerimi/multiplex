import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../game/models/tile.dart';
import '../game/multiplex.dart';
import '../game/tool.dart';
import '../game/ui/sidebar.dart';
import '../services/notification_service.dart';

class GameScreen extends StatefulWidget {
  final Multiplex game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Map<String, dynamic>? progressData;
  bool hasUnsavedChanges = false;
  final NotificationService _notificationService = NotificationService();
  late final GameController _gameController;

  @override
  void initState() {
    super.initState();

    // Get or create game controller
    _gameController = Get.put(GameController());

    // Initialize notification service with context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(context);
      _initializeGame();
    });

    // Get progress data from route arguments
    final args = Get.arguments as Map<String, dynamic>?;
    debugPrint('[GameScreen] Route arguments: $args');
    progressData = args?['progress'] as Map<String, dynamic>?;
    debugPrint('[GameScreen] Progress data: $progressData');

    // Set up callback to rebuild UI when level changes
    widget.game.onLevelChanged = () {
      setState(() {
        hasUnsavedChanges = true;
      });
      _syncGameStatsToController();
    };

    // Set up callback when stats change in the game
    widget.game.onStatsChanged = () {
      _syncGameStatsToController();
    };

    // Load progress if provided
    if (progressData != null) {
      _loadProgress(progressData!);
    } else {
      // Start fresh game
      widget.game.levelManager.startNewGame();
    }
  }

  /// Initialize achievements and game state
  Future<void> _initializeGame() async {
    try {
      // Initialize achievements
      await _gameController.initializeAchievements();

      // Sync initial game state
      _syncGameStatsToController();

      // Start auto-save
      _gameController.startAutoSave();
    } catch (e) {
      debugPrint('Error initializing game: $e');
    }
  }

  /// Sync game stats from Multiplex to GameController
  void _syncGameStatsToController() {
    _gameController.updateStatsAndCheck(
      currentLevel: widget.game.levelManager.currentLevelNumber,
      totalScore: widget.game.totalScore,
      tilesProcessed: widget.game.tilesProcessed,
      beltsPlaced: widget.game.beltsPlaced,
      operatorsPlaced: widget.game.operatorsPlaced,
      extractorsPlaced: widget.game.extractorsPlaced,
      levelsCompleted: widget.game.levelsCompleted,
      totalPlaytimeSeconds: widget.game.totalPlaytime.toInt(),
    );
  }

  void _loadProgress(Map<String, dynamic> data) {
    debugPrint('Loading progress: $data');

    try {
      // Import game state from progress data
   //   widget.game.importState(data);

      // Sync stats to controller
      _syncGameStatsToController();

      debugPrint('Progress loaded successfully');
    } catch (e) {
      debugPrint('Error loading progress: $e');

      // Fallback to new game if loading fails
      widget.game.levelManager.startNewGame();

      Get.snackbar(
        'Load Error',
        'Failed to load progress. Starting a new game.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!hasUnsavedChanges) {
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
              await _saveProgress();
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

  Future<void> _saveProgress() async {
    try {
      // Sync stats to controller first
      _syncGameStatsToController();

      // Save progress via controller
      final success = await _gameController.saveProgress();

      if (success) {
        setState(() {
          hasUnsavedChanges = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
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
              onPressed: _saveProgress,
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
        body: Row(
          children: [
            Expanded(
              child: GameWidget(game: widget.game),
            ),
            // Use ValueListenableBuilder to reactively update sidebar when state changes
            ValueListenableBuilder<Tool>(
              valueListenable: widget.game.inputManager.selectedToolNotifier,
              builder: (context, selectedTool, child) {
                return ValueListenableBuilder<BeltDirection>(
                  valueListenable: widget.game.inputManager.currentBeltDirectionNotifier,
                  builder: (context, beltDirection, child) {
                    return ValueListenableBuilder<BeltDirection>(
                      valueListenable: widget.game.inputManager.currentOperatorDirectionNotifier,
                      builder: (context, operatorDirection, child) {
                        return Sidebar(
                          selectedTool: selectedTool,
                          beltDirection: beltDirection,
                          operatorDirection: operatorDirection,
                          unlockedOperators: widget.game.levelManager.currentLevel?.unlockedOperators ?? [],
                          onToolSelected: (tool) {
                            widget.game.inputManager.selectedTool = tool;
                          },
                          onRotateBelt: () {
                            widget.game.inputManager.rotateBeltDirection();
                          },
                        );
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
  }
}
