import 'package:flutter/material.dart';

import '../models/tile.dart';

class TileManager {
  // Tile grid storage
  final Map<String, Tile> _tiles = {};

  TileManager();

  Tile getTile(int x, int y) {
    final key = '$x,$y';
    return _tiles[key] ?? Tile.empty();
  }

  void setTile(int x, int y, Tile tile) {
    final key = '$x,$y';
    _tiles[key] = tile;
  }

  void removeTile(int x, int y) {
    final key = '$x,$y';
    _tiles.remove(key);
  }

  void placeFactory(int startX, int startY, int width, int height) {
    // Place the origin tile at the center
    final originX = startX + width ~/ 2;
    final originY = startY + height ~/ 2;
    final originKey = '$originX,$originY';
    _tiles[originKey] = Tile.factoryOrigin();

    // Place reference tiles for all other positions
    for (int x = startX; x < startX + width; x++) {
      for (int y = startY; y < startY + height; y++) {
        if (x == originX && y == originY) continue; // Skip origin
        final key = '$x,$y';
        _tiles[key] = Tile.factoryReference(originX, originY);
      }
    }
  }

  void placeBelt(int x, int y, BeltDirection direction) {
    final key = '$x,$y';
    _tiles[key] = Tile.belt(direction: direction);
  }

  void placeExtractor(int x, int y, {int extractValue = 1}) {
    final key = '$x,$y';
    _tiles[key] = Tile.extractor(extractValue: extractValue);
  }

  void placeNumber(int x, int y, int value) {
    final key = '$x,$y';
    _tiles[key] = Tile.number(value: value);
  }

  void placeOperator(int x, int y, OperatorType operatorType, BeltDirection direction) {
    // Operator is 3 tiles: left/top (input), middle (operator origin), right/bottom (input)
    // x,y is the middle tile position

    final bool isHorizontal = direction == BeltDirection.left || direction == BeltDirection.right;

    // Place origin tile at center
    final originKey = '$x,$y';
    _tiles[originKey] = Tile(
      type: TileType.operator,
      color: Colors.purple[700],
      operatorType: operatorType,
      isOrigin: true,
      width: isHorizontal ? 3 : 1,
      height: isHorizontal ? 1 : 3,
    );

    // Place input tiles
    if (isHorizontal) {
      // Left input tile
      final leftKey = '${x - 1},$y';
      _tiles[leftKey] = Tile(
        type: TileType.operator,
        color: Colors.purple[700],
        operatorType: operatorType,
        isOrigin: false,
        originX: x,
        originY: y,
      );
      // Right input tile
      final rightKey = '${x + 1},$y';
      _tiles[rightKey] = Tile(
        type: TileType.operator,
        color: Colors.purple[700],
        operatorType: operatorType,
        isOrigin: false,
        originX: x,
        originY: y,
      );
    } else {
      // Top input tile
      final topKey = '$x,${y - 1}';
      _tiles[topKey] = Tile(
        type: TileType.operator,
        color: Colors.purple[700],
        operatorType: operatorType,
        isOrigin: false,
        originX: x,
        originY: y,
      );
      // Bottom input tile
      final bottomKey = '$x,${y + 1}';
      _tiles[bottomKey] = Tile(
        type: TileType.operator,
        color: Colors.purple[700],
        operatorType: operatorType,
        isOrigin: false,
        originX: x,
        originY: y,
      );
    }
  }

  Map<String, Tile> get tiles => _tiles;
}
