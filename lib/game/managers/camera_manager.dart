import 'package:flame/game.dart';

/// Manages camera transformations including zoom, pan, and coordinate conversions.
/// Handles the relationship between screen space and grid space.
class CameraManager {
  static const double baseTileSize = 64.0; // Base tile size
  double tileSize = baseTileSize; // Current tile size (affected by zoom)
  Vector2 gridOffset = Vector2.zero(); // Grid position offset (affected by pan)

  /// Initialize grid offset to center at (0, 0) given viewport size
  void initializeGridOffset(Vector2 viewportSize) {
    if (viewportSize.x > 0 && viewportSize.y > 0) {
      gridOffset = Vector2(-viewportSize.x / 2, -viewportSize.y / 2);
    }
  }

  /// Update grid offset when viewport size changes
  void updateGridOffset(Vector2 viewportSize) {
    // Center the grid at (0, 0) by setting offset to negative viewport center
    // gridOffset represents the world position of the top-left corner of the viewport
    gridOffset = Vector2(
      -viewportSize.x / 2,
      -viewportSize.y / 2,
    );
  }

  /// Pan the view by delta
  void pan(Vector2 delta) {
    gridOffset -= delta;
  }

  /// Zoom in (increase tile size)
  void zoomIn() {
    _updateTileSize(0.1);
  }

  /// Zoom out (decrease tile size)
  void zoomOut() {
    _updateTileSize(-0.1);
  }

  /// Zoom by delta (positive = zoom in, negative = zoom out)
  void zoom(double delta) {
    _updateTileSize(delta);
  }

  /// Update tile size with clamping
  void _updateTileSize(double delta) {
    tileSize = (tileSize + delta * baseTileSize)
        .clamp(baseTileSize / 2, baseTileSize * 2);
  }

  /// Convert grid coordinates to screen coordinates
  Vector2 gridToScreen(Vector2 gridPos) {
    return Vector2(
      gridPos.x * tileSize - gridOffset.x,
      gridPos.y * tileSize - gridOffset.y,
    );
  }

  /// Convert screen coordinates to grid coordinates
  Vector2 screenToGrid(Vector2 screenPos) {
    return Vector2(
      ((screenPos.x + gridOffset.x) / tileSize).floor().toDouble(),
      ((screenPos.y + gridOffset.y) / tileSize).floor().toDouble(),
    );
  }
}
