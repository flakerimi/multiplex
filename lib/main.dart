import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/models/tile.dart';
import 'game/multiplex.dart';
import 'game/tool.dart';
import 'game/ui/sidebar.dart';

void main() {
  final Multiplex multiplexGame = Multiplex();
  runApp(MyApp(game: multiplexGame));
}

class MyApp extends StatelessWidget {
  final Multiplex game;

  const MyApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(game: game),
    );
  }
}

class GameScreen extends StatefulWidget {
  final Multiplex game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Set up callback to rebuild UI when level changes
    widget.game.onLevelChanged = () {
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
