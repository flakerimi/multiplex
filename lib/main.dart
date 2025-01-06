import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/models/operation.dart';
import 'game/multiplex.dart';

void main() {
  final Multiplex multiplexGame =
      Multiplex(); // Create a single instance of the game
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

class GameScreen extends StatelessWidget {
  final Multiplex game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            // Dynamically scale the game area to fill available space
            child: Stack(
              children: [
                GameWidget(game: game),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    children: [
                      // ElevatedButton(
                      //   onPressed: () {
                      //     game.zoomIn();
                      //   },
                      //   child: const Text('Zoom In'),
                      // ),
                      // const SizedBox(height: 8),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     game.zoomOut();
                      //   },
                      //   child: const Text('Zoom Out'),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 200, // Fixed size for the sidebar
            color: Colors.deepPurple[400],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                _buildOperationTile(Operation.add),
                const SizedBox(height: 8),
                _buildOperationTile(Operation.subtract),
                const SizedBox(height: 8),
                _buildOperationTile(Operation.multiply),
                const SizedBox(height: 8),
                _buildOperationTile(Operation.divide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTile(Operation operation) {
    return Draggable<Operation>(
      data: operation,
      feedback: Container(
        width: 80,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          operation.symbol,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      child: Container(
        width: 80,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          operation.symbol,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
