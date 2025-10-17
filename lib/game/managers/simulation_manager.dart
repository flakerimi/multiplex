import '../models/tile.dart';
import 'tile_manager.dart';

/// Manages all game simulation logic including belt movement, operator processing,
/// and extractor spawning. Runs on fixed time intervals.
class SimulationManager {
  final TileManager tileManager;

  // Simulation timers
  double _extractorSpawnTimer = 0.0;
  double _beltMoveTimer = 0.0;
  double _operatorProcessTimer = 0.0;

  static const double extractorSpawnInterval = 1.0; // Spawn every 1 second
  static const double beltMoveInterval = 0.5; // Move every 0.5 seconds
  static const double operatorProcessInterval = 0.5; // Process every 0.5 seconds

  // Callback for when a number is delivered to factory
  Function(int value)? onFactoryDelivery;

  SimulationManager({required this.tileManager});

  /// Update all simulation systems with delta time
  void update(double dt) {
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

  /// Spawn numbers from extractor tiles onto adjacent belts
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
        [extractorX, extractorY + 1], // Below
        [extractorX, extractorY - 1], // Above
        [extractorX + 1, extractorY], // Right
        [extractorX - 1, extractorY], // Left
      ];

      for (final pos in adjacentPositions) {
        final spawnX = pos[0];
        final spawnY = pos[1];
        final targetTile = tileManager.getTile(spawnX, spawnY);

        // Only spawn directly onto belts that aren't carrying anything
        if (targetTile.type == TileType.belt && targetTile.carryingNumber == null) {
          final updatedBelt = targetTile.copyWith(carryingNumber: extractValue);
          tileManager.setTile(spawnX, spawnY, updatedBelt);
          break; // Only spawn once per cycle
        }
      }
    }
  }

  /// Move numbers along belts and deliver to factory/operators
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
        // Deliver to factory via callback
        onFactoryDelivery?.call(belt.carryingNumber!);
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

  /// Process operator tiles - combine inputs and produce outputs
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

  /// Get grid offset for a direction
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

  /// Get opposite grid offset for a direction
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
}
