import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Multiplex extends FlameGame
    with PanDetector, ScrollDetector, TapDetector, KeyboardEvents {
  static const double baseTileSize = 64.0; // Base tile size
  double tileSize = baseTileSize; // Current tile size for the grid
  Vector2 gridOffset = Vector2.zero(); // Track the grid's position

  final Set<LogicalKeyboardKey> pressedKeys = {}; // Track pressed keys

  @override
  Future<void> onLoad() async {
    camera.viewfinder.zoom = 1.0; // Default zoom level
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    // Dynamically set the viewport size to always match the widget size
    camera.viewport = FixedResolutionViewport(resolution: canvasSize);
    super.onGameResize(canvasSize);
  }

  @override
  Color backgroundColor() => const Color(0xFF90EE90).withOpacity(0.5);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawInfiniteGrid(canvas);
    _drawCellCoordinates(canvas);
    _drawViewportBorder(canvas);
  }

  void _drawInfiniteGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final Rect visibleRect = camera.viewport.size.toRect();
    final double startX =
        (visibleRect.left + gridOffset.x) ~/ tileSize * tileSize;
    final double startY =
        (visibleRect.top + gridOffset.y) ~/ tileSize * tileSize;
    final double endX =
        (visibleRect.right + gridOffset.x) ~/ tileSize * tileSize + tileSize;
    final double endY =
        (visibleRect.bottom + gridOffset.y) ~/ tileSize * tileSize + tileSize;

    // Draw vertical grid lines
    for (double x = startX; x <= endX; x += tileSize) {
      canvas.drawLine(Offset(x - gridOffset.x, 0),
          Offset(x - gridOffset.x, visibleRect.bottom), paint);
    }

    // Draw horizontal grid lines
    for (double y = startY; y <= endY; y += tileSize) {
      canvas.drawLine(Offset(0, y - gridOffset.y),
          Offset(visibleRect.right, y - gridOffset.y), paint);
    }
  }

  void _drawCellCoordinates(Canvas canvas) {
    final Rect visibleRect = camera.viewport.size.toRect();
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final double startX =
        (visibleRect.left + gridOffset.x) ~/ tileSize * tileSize;
    final double startY =
        (visibleRect.top + gridOffset.y) ~/ tileSize * tileSize;
    final double endX =
        (visibleRect.right + gridOffset.x) ~/ tileSize * tileSize + tileSize;
    final double endY =
        (visibleRect.bottom + gridOffset.y) ~/ tileSize * tileSize + tileSize;

    for (double x = startX; x <= endX; x += tileSize) {
      for (double y = startY; y <= endY; y += tileSize) {
        final gridX = (x / tileSize).floor();
        final gridY = (y / tileSize).floor();
        textPaint.render(
          canvas,
          '($gridX, $gridY)',
          Vector2(x - gridOffset.x + 5,
              y - gridOffset.y + 5), // Offset text slightly within the cell
        );
      }
    }
  }

  void _drawViewportBorder(Canvas canvas) {
    final Paint borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Rect visibleRect = camera.viewport.size.toRect();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, visibleRect.width, visibleRect.height),
      borderPaint,
    );
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      pressedKeys.remove(event.logicalKey);
    }
    return KeyEventResult.handled; // Indicate that the event was handled
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Check for Shift (either left or right) for zooming
    if (pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.shiftRight)) {
      // Zooming with Shift + Drag
      final delta = info.delta.global;
      if (delta.y > 0) {
        _updateTileSize(-0.01); // Zoom out
      } else if (delta.y < 0) {
        _updateTileSize(0.01); // Zoom in
      }
    } else if (pressedKeys.contains(LogicalKeyboardKey.space)) {
      // Panning with Space + Drag
      gridOffset -= info.delta.global;
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    // Use scroll for zooming
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
}
