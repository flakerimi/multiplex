import 'package:flutter/material.dart';

enum TileType {
  empty,
  factory,
  belt,
  extractor,
  number,
  operator,
}

enum OperatorType {
  add,
  subtract,
  multiply,
  divide,
}

enum BeltDirection {
  up,
  down,
  left,
  right,
}

class Tile {
  final TileType type;
  final Color? color;
  final bool isOrigin; // Is this the origin tile of a multi-tile entity?
  final int? originX; // X coordinate of the origin tile
  final int? originY; // Y coordinate of the origin tile
  final int width; // Width in tiles (for multi-tile entities)
  final int height; // Height in tiles (for multi-tile entities)
  final int? targetNumber; // Target number for factory
  final int? currentValue; // Current value for factory
  final int? level; // Level for factory
  final BeltDirection? beltDirection; // Direction for belt tiles
  final int? extractValue; // Value to extract for extractor tiles
  final OperatorType? operatorType; // Type of operator
  final int? numberValue; // Value for number tiles
  final int? carryingNumber; // Number being carried by belt/extractor
  final double movementProgress; // 0.0 to 1.0, for smooth animations
  final int? movingToX; // Target X coordinate for animation
  final int? movingToY; // Target Y coordinate for animation

  Tile({
    required this.type,
    this.color,
    this.isOrigin = false,
    this.originX,
    this.originY,
    this.width = 1,
    this.height = 1,
    this.targetNumber,
    this.currentValue,
    this.level,
    this.beltDirection,
    this.extractValue,
    this.operatorType,
    this.numberValue,
    this.carryingNumber,
    this.movementProgress = 0.0,
    this.movingToX,
    this.movingToY,
  });

  // Factory constructor for empty tiles
  factory Tile.empty() => Tile(type: TileType.empty);

  // Factory constructor for factory origin tile
  factory Tile.factoryOrigin({
    int targetNumber = 10,
    int currentValue = 0,
    int level = 1,
  }) =>
      Tile(
        type: TileType.factory,
        color: Colors.blueAccent,
        isOrigin: true,
        width: 5,
        height: 5,
        targetNumber: targetNumber,
        currentValue: currentValue,
        level: level,
      );

  // Factory constructor for factory reference tiles
  factory Tile.factoryReference(int originX, int originY) => Tile(
        type: TileType.factory,
        color: Colors.blueAccent,
        isOrigin: false,
        originX: originX,
        originY: originY,
      );

  // Factory constructor for belt tiles
  factory Tile.belt({BeltDirection direction = BeltDirection.right}) => Tile(
        type: TileType.belt,
        color: Colors.grey[700],
        beltDirection: direction,
      );

  // Factory constructor for extractor tiles
  factory Tile.extractor({int extractValue = 1}) => Tile(
        type: TileType.extractor,
        color: const Color.fromARGB(255, 35, 133, 79),
        extractValue: extractValue,
      );

  // Factory constructor for number tiles
  factory Tile.number({required int value}) => Tile(
        type: TileType.number,
        color: Colors.amber[700],
        numberValue: value,
      );

  // Factory constructor for operator tiles
  factory Tile.operator({required OperatorType operatorType}) => Tile(
        type: TileType.operator,
        color: Colors.purple[700],
        operatorType: operatorType,
      );

  // Copy with method for updating tiles
  Tile copyWith({
    int? carryingNumber,
    bool clearCarrying = false,
    double? movementProgress,
    int? movingToX,
    int? movingToY,
    bool clearMovement = false,
  }) {
    return Tile(
      type: type,
      color: color,
      isOrigin: isOrigin,
      originX: originX,
      originY: originY,
      width: width,
      height: height,
      targetNumber: targetNumber,
      currentValue: currentValue,
      level: level,
      beltDirection: beltDirection,
      extractValue: extractValue,
      operatorType: operatorType,
      numberValue: numberValue,
      carryingNumber: clearCarrying ? null : (carryingNumber ?? this.carryingNumber),
      movementProgress: clearMovement ? 0.0 : (movementProgress ?? this.movementProgress),
      movingToX: clearMovement ? null : (movingToX ?? this.movingToX),
      movingToY: clearMovement ? null : (movingToY ?? this.movingToY),
    );
  }

  Color getColor() {
    switch (type) {
      case TileType.empty:
        return Colors.transparent;
      case TileType.factory:
        return color ?? Colors.blueAccent;
      case TileType.belt:
        return color ?? Colors.grey[700]!;
      case TileType.extractor:
        return color ?? const Color.fromARGB(255, 35, 133, 79); 
      case TileType.number:
        return color ?? Colors.amber[700]!;
      case TileType.operator:
        return color ?? Colors.purple[700]!;
    }
  }
}
