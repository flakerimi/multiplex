import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/tile.dart';
import 'tile_manager.dart';

class RenderManager {
  final TileManager tileManager;
  final double Function() getTileSize;
  final Vector2 Function() getGridOffset;

  RenderManager({
    required this.tileManager,
    required this.getTileSize,
    required this.getGridOffset,
  });

  void drawTiles(Canvas canvas, Rect visibleRect) {
    final tileSize = getTileSize();
    final gridOffset = getGridOffset();

    final int startX = ((visibleRect.left + gridOffset.x) / tileSize).floor();
    final int startY = ((visibleRect.top + gridOffset.y) / tileSize).floor();
    final int endX = ((visibleRect.right + gridOffset.x) / tileSize).ceil();
    final int endY = ((visibleRect.bottom + gridOffset.y) / tileSize).ceil();

    // Track which origin tiles we've already drawn
    final Set<String> drawnOrigins = {};

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final tile = tileManager.getTile(x, y);
        // Skip factory tiles - they're rendered by FactoryComponent
        if (tile.type != TileType.empty && tile.type != TileType.factory) {
          if (tile.isOrigin) {
            _drawOriginTile(canvas, x, y, tile, drawnOrigins);
          } else {
            _drawSingleTile(canvas, x, y, tile);
          }
        }
      }
    }
  }

  void _drawOriginTile(
      Canvas canvas, int x, int y, Tile tile, Set<String> drawnOrigins) {
    final originKey = '$x,$y';
    if (drawnOrigins.contains(originKey)) return;

    drawnOrigins.add(originKey);
    final tileSize = getTileSize();
    final gridOffset = getGridOffset();

    // For operators, draw the 3-tile layout
    if (tile.type == TileType.operator && tile.operatorType != null) {
      _drawOperatorLayout(canvas, x, y, tile);
      return;
    }

    final paint = Paint()
      ..color = tile.getColor()
      ..style = PaintingStyle.fill;

    final screenX = (x - tile.width ~/ 2) * tileSize - gridOffset.x;
    final screenY = (y - tile.height ~/ 2) * tileSize - gridOffset.y;

    canvas.drawRect(
      Rect.fromLTWH(
        screenX,
        screenY,
        tileSize * tile.width,
        tileSize * tile.height,
      ),
      paint,
    );

    // Draw border for factory tiles
    if (tile.type == TileType.factory) {
      _drawFactoryDetails(canvas, screenX, screenY, tile);
    }
  }

  void _drawFactoryDetails(Canvas canvas, double screenX, double screenY, Tile tile) {
    final tileSize = getTileSize();

    final borderPaint = Paint()
      ..color = Colors.orange[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(
        screenX,
        screenY,
        tileSize * tile.width,
        tileSize * tile.height,
      ),
      borderPaint,
    );

    // Draw factory text
    final centerX = screenX + (tileSize * tile.width) / 2;
    final centerY = screenY + (tileSize * tile.height) / 2;

    // Calculate font sizes based on tile size
    final double baseFontSize = tileSize * 0.8;
    final double progressFontSize = tileSize * 0.5;
    final double levelFontSize = tileSize * 0.3;

    // Draw current value (big number)
    TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: baseFontSize,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      '${tile.currentValue ?? 0}',
      Vector2(centerX, centerY - tileSize * 0.8),
      anchor: Anchor.center,
    );

    // Draw progress (0/10)
    TextPaint(
      style: TextStyle(
        color: Colors.green,
        fontSize: progressFontSize,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      '${tile.currentValue ?? 0}/${tile.targetNumber ?? 10}',
      Vector2(centerX, centerY - tileSize * 0.1),
      anchor: Anchor.center,
    );

    // Draw level
    TextPaint(
      style: TextStyle(
        color: Colors.white70,
        fontSize: levelFontSize,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      'LEVEL ${tile.level ?? 1}',
      Vector2(centerX, centerY + tileSize * 0.4),
      anchor: Anchor.center,
    );

    // Draw "ADDER", "UNLOCKED", "NEXT LEVEL" text
    final statusFontSize = levelFontSize * 0.8;
    final statusPaint = TextPaint(
      style: TextStyle(
        color: Colors.white60,
        fontSize: statusFontSize,
        fontWeight: FontWeight.normal,
      ),
    );

    statusPaint.render(
      canvas,
      'ADDER',
      Vector2(centerX, centerY + tileSize * 0.7),
      anchor: Anchor.center,
    );

    statusPaint.render(
      canvas,
      'UNLOCKED',
      Vector2(centerX, centerY + tileSize * 0.95),
      anchor: Anchor.center,
    );

    statusPaint.render(
      canvas,
      'NEXT LEVEL',
      Vector2(centerX, centerY + tileSize * 1.2),
      anchor: Anchor.center,
    );
  }

  void _drawSingleTile(Canvas canvas, int x, int y, Tile tile) {
    final tileSize = getTileSize();
    final gridOffset = getGridOffset();

    final screenX = x * tileSize - gridOffset.x;
    final screenY = y * tileSize - gridOffset.y;

    // Skip operator reference tiles - they're drawn by _drawOperatorLayout
    if (tile.type == TileType.operator && !tile.isOrigin) {
      return;
    }

    // Draw shadow first for depth
    if (tile.type != TileType.empty) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRect(
        Rect.fromLTWH(screenX + 2, screenY + 2, tileSize, tileSize),
        shadowPaint,
      );
    }

    // Main tile background
    final paint = Paint()
      ..color = tile.getColor()
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(screenX, screenY, tileSize, tileSize),
      paint,
    );

    // Draw belt with realistic conveyor design
    if (tile.type == TileType.belt && tile.beltDirection != null) {
      _drawConveyorBelt(canvas, screenX, screenY, tile.beltDirection!, tileSize);

      // Draw carrying number on belt with smooth movement
      if (tile.carryingNumber != null) {
        // Calculate interpolated position if moving
        double numberX = screenX;
        double numberY = screenY;

        if (tile.movementProgress > 0 && tile.movingToX != null && tile.movingToY != null) {
          final destScreenX = tile.movingToX! * tileSize - gridOffset.x;
          final destScreenY = tile.movingToY! * tileSize - gridOffset.y;

          // Interpolate between current and destination position
          numberX = screenX + (destScreenX - screenX) * tile.movementProgress;
          numberY = screenY + (destScreenY - screenY) * tile.movementProgress;
        }

        _drawNumberValue(canvas, numberX, numberY, tile.carryingNumber!);
      }
    }

    // Draw extractor icon
    if (tile.type == TileType.extractor) {
      _drawExtractorIcon(canvas, screenX, screenY, tile.extractValue);
    }

    // Draw number value
    if (tile.type == TileType.number && tile.numberValue != null) {
      _drawNumberValue(canvas, screenX, screenY, tile.numberValue!);
    }

  }

  void _drawOperatorLayout(Canvas canvas, int x, int y, Tile tile) {
    final tileSize = getTileSize();
    final gridOffset = getGridOffset();
    final isHorizontal = tile.width == 3;

    // Get operator colors - one color per operator type
    Color operatorColor;
    String symbol;
    switch (tile.operatorType!) {
      case OperatorType.add:
        operatorColor = const Color(0xFF4CAF50); // Green
        symbol = '+';
        break;
      case OperatorType.subtract:
        operatorColor = const Color(0xFFF44336); // Red
        symbol = '-';
        break;
      case OperatorType.multiply:
        operatorColor = const Color(0xFF9C27B0); // Purple
        symbol = '×';
        break;
      case OperatorType.divide:
        operatorColor = const Color(0xFF00BCD4); // Cyan
        symbol = '÷';
        break;
    }

    // Use slightly darker/lighter shades for A and B sections
    final lightColor = Color.lerp(operatorColor, Colors.white, 0.3)!;
    final darkColor = Color.lerp(operatorColor, Colors.black, 0.2)!;

    if (isHorizontal) {
      // Horizontal layout: | A | + | B |
      // Draw left tile (input A)
      final leftX = (x - 1) * tileSize - gridOffset.x;
      final leftY = y * tileSize - gridOffset.y;
      _drawOperatorSection(canvas, leftX, leftY, 'A', lightColor, operatorColor);

      // Draw center tile (operator symbol)
      final centerX = x * tileSize - gridOffset.x;
      final centerY = y * tileSize - gridOffset.y;
      _drawOperatorSection(canvas, centerX, centerY, symbol, operatorColor, operatorColor, isSymbol: true);

      // Draw right tile (input B)
      final rightX = (x + 1) * tileSize - gridOffset.x;
      final rightY = y * tileSize - gridOffset.y;
      _drawOperatorSection(canvas, rightX, rightY, 'B', darkColor, operatorColor);

      // Draw output number if present
      if (tile.carryingNumber != null) {
        _drawNumberValue(canvas, centerX, centerY + tileSize * 0.7, tile.carryingNumber!);
      }
    } else {
      // Vertical layout
      // Draw top tile (input A)
      final topX = x * tileSize - gridOffset.x;
      final topY = (y - 1) * tileSize - gridOffset.y;
      _drawOperatorSection(canvas, topX, topY, 'A', lightColor, operatorColor);

      // Draw center tile (operator symbol)
      final centerX = x * tileSize - gridOffset.x;
      final centerY = y * tileSize - gridOffset.y;
      _drawOperatorSection(canvas, centerX, centerY, symbol, operatorColor, operatorColor, isSymbol: true);

      // Draw bottom tile (input B)
      final bottomX = x * tileSize - gridOffset.x;
      final bottomY = (y + 1) * tileSize - gridOffset.y;
      _drawOperatorSection(canvas, bottomX, bottomY, 'B', darkColor, operatorColor);

      // Draw output number if present
      if (tile.carryingNumber != null) {
        _drawNumberValue(canvas, centerX + tileSize * 0.7, centerY, tile.carryingNumber!);
      }
    }
  }

  void _drawOperatorSection(
    Canvas canvas,
    double x,
    double y,
    String label,
    Color bgColor,
    Color borderColor, {
    bool isSymbol = false,
  }) {
    final tileSize = getTileSize();

    // Draw background with gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        bgColor.withValues(alpha: 0.9),
        bgColor.withValues(alpha: 0.7),
      ],
    );

    final bgPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(x, y, tileSize, tileSize));
    canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize), borderPaint);

    // Draw dividers (pipes |)
    final dividerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 2.0;

    // Left divider
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y + tileSize),
      dividerPaint,
    );

    // Right divider
    canvas.drawLine(
      Offset(x + tileSize, y),
      Offset(x + tileSize, y + tileSize),
      dividerPaint,
    );

    // Draw label
    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;

    TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: isSymbol ? tileSize * 0.6 : tileSize * 0.5,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
    ).render(
      canvas,
      label,
      Vector2(centerX, centerY),
      anchor: Anchor.center,
    );
  }

  void _drawConveyorBelt(Canvas canvas, double x, double y, BeltDirection direction, double tileSize) {
    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;
    final isHorizontal = (direction == BeltDirection.left || direction == BeltDirection.right);

    // Draw conveyor belt with gradient and rails
    final beltRect = Rect.fromLTWH(x, y, tileSize, tileSize);

    // Gradient for 3D effect
    final gradient = LinearGradient(
      begin: isHorizontal ? Alignment.topCenter : Alignment.centerLeft,
      end: isHorizontal ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [
        Colors.grey[800]!,
        Colors.grey[700]!,
        Colors.grey[600]!,
        Colors.grey[700]!,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(beltRect);

    canvas.drawRect(beltRect, gradientPaint);

    // Draw side rails for realistic conveyor look
    final railPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.fill;

    if (isHorizontal) {
      // Top and bottom rails
      canvas.drawRect(Rect.fromLTWH(x, y, tileSize, tileSize * 0.1), railPaint);
      canvas.drawRect(Rect.fromLTWH(x, y + tileSize * 0.9, tileSize, tileSize * 0.1), railPaint);
    } else {
      // Left and right rails
      canvas.drawRect(Rect.fromLTWH(x, y, tileSize * 0.1, tileSize), railPaint);
      canvas.drawRect(Rect.fromLTWH(x + tileSize * 0.9, y, tileSize * 0.1, tileSize), railPaint);
    }

    // Draw movement lines on belt
    final linePaint = Paint()
      ..color = Colors.grey[500]!.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (isHorizontal) {
      for (double i = 0.2; i < 1.0; i += 0.15) {
        canvas.drawLine(
          Offset(x + tileSize * i, y + tileSize * 0.15),
          Offset(x + tileSize * i, y + tileSize * 0.85),
          linePaint,
        );
      }
    } else {
      for (double i = 0.2; i < 1.0; i += 0.15) {
        canvas.drawLine(
          Offset(x + tileSize * 0.15, y + tileSize * i),
          Offset(x + tileSize * 0.85, y + tileSize * i),
          linePaint,
        );
      }
    }

    // Draw directional arrow
    final arrowPaint = Paint()
      ..color = Colors.amber[400]!
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final arrowSize = tileSize * 0.25;
    final path = Path();

    switch (direction) {
      case BeltDirection.right:
        path.moveTo(centerX - arrowSize * 0.8, centerY - arrowSize);
        path.lineTo(centerX + arrowSize, centerY);
        path.lineTo(centerX - arrowSize * 0.8, centerY + arrowSize);
        path.lineTo(centerX - arrowSize * 0.3, centerY);
        break;
      case BeltDirection.left:
        path.moveTo(centerX + arrowSize * 0.8, centerY - arrowSize);
        path.lineTo(centerX - arrowSize, centerY);
        path.lineTo(centerX + arrowSize * 0.8, centerY + arrowSize);
        path.lineTo(centerX + arrowSize * 0.3, centerY);
        break;
      case BeltDirection.down:
        path.moveTo(centerX - arrowSize, centerY - arrowSize * 0.8);
        path.lineTo(centerX, centerY + arrowSize);
        path.lineTo(centerX + arrowSize, centerY - arrowSize * 0.8);
        path.lineTo(centerX, centerY - arrowSize * 0.3);
        break;
      case BeltDirection.up:
        path.moveTo(centerX - arrowSize, centerY + arrowSize * 0.8);
        path.lineTo(centerX, centerY - arrowSize);
        path.lineTo(centerX + arrowSize, centerY + arrowSize * 0.8);
        path.lineTo(centerX, centerY + arrowSize * 0.3);
        break;
    }
    path.close();

    // Draw arrow with glow effect
    canvas.drawPath(path, arrowPaint);

    // Arrow outline for better visibility
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);
  }

  void _drawExtractorIcon(Canvas canvas, double x, double y, int? extractValue) {
    final tileSize = getTileSize();
    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;
    final iconSize = tileSize * 0.35;

    // Metallic gradient for industrial look
    final gradient = RadialGradient(
      colors: [
        const Color(0xFF4CAF50),
        const Color(0xFF2E7D32),
        const Color(0xFF1B5E20),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final iconPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: iconSize),
      );

    // Draw main extractor circle
    canvas.drawCircle(Offset(centerX, centerY), iconSize, iconPaint);

    // Draw metallic rim
    final rimPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(centerX, centerY), iconSize, rimPaint);

    // Draw inner gears/detail circles
    final detailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(centerX, centerY), iconSize * 0.6, detailPaint);
    canvas.drawCircle(Offset(centerX, centerY), iconSize * 0.3, detailPaint);

    // Draw extract value if present
    if (extractValue != null) {
      // Background circle for number
      final numberBg = Paint()
        ..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(Offset(centerX, centerY), iconSize * 0.5, numberBg);

      TextPaint(
        style: TextStyle(
          color: const Color(0xFF1B5E20),
          fontSize: tileSize * 0.35,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ).render(
        canvas,
        '$extractValue',
        Vector2(centerX, centerY),
        anchor: Anchor.center,
      );
    }
  }

  void drawInfiniteGrid(Canvas canvas, Rect visibleRect) {
    final tileSize = getTileSize();
    final gridOffset = getGridOffset();

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Calculate which grid cells are visible (same logic as drawTiles)
    final int startGridX = ((visibleRect.left + gridOffset.x) / tileSize).floor();
    final int startGridY = ((visibleRect.top + gridOffset.y) / tileSize).floor();
    final int endGridX = ((visibleRect.right + gridOffset.x) / tileSize).ceil();
    final int endGridY = ((visibleRect.bottom + gridOffset.y) / tileSize).ceil();

    // Draw vertical grid lines at each grid cell boundary
    for (int gridX = startGridX; gridX <= endGridX; gridX++) {
      final double screenX = gridX * tileSize - gridOffset.x;
      canvas.drawLine(
        Offset(screenX, 0),
        Offset(screenX, visibleRect.bottom),
        paint,
      );
    }

    // Draw horizontal grid lines at each grid cell boundary
    for (int gridY = startGridY; gridY <= endGridY; gridY++) {
      final double screenY = gridY * tileSize - gridOffset.y;
      canvas.drawLine(
        Offset(0, screenY),
        Offset(visibleRect.right, screenY),
        paint,
      );
    }
  }

  void drawCellCoordinates(Canvas canvas, Rect visibleRect, double baseTileSize) {
    final tileSize = getTileSize();
    final gridOffset = getGridOffset();

    final double fontSize = (tileSize / baseTileSize) * 12;
    final textPaint = TextPaint(
      style: TextStyle(
        color: Colors.black.withValues(alpha: 0.1),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );

    // Use the EXACT same approach as the downloaded working version
    final double startX = (visibleRect.left + gridOffset.x) ~/ tileSize * tileSize;
    final double startY = (visibleRect.top + gridOffset.y) ~/ tileSize * tileSize;
    final double endX = (visibleRect.right + gridOffset.x) ~/ tileSize * tileSize + tileSize;
    final double endY = (visibleRect.bottom + gridOffset.y) ~/ tileSize * tileSize + tileSize;

    for (double x = startX; x <= endX; x += tileSize) {
      for (double y = startY; y <= endY; y += tileSize) {
        final gridX = (x / tileSize).floor();
        final gridY = (y / tileSize).floor();

        final double textOffset = (tileSize / baseTileSize) * 5;
        textPaint.render(
          canvas,
          '($gridX, $gridY)',
          Vector2(
            x - gridOffset.x + textOffset,
            y - gridOffset.y + textOffset,
          ),
        );
      }
    }
  }


  void _drawNumberValue(Canvas canvas, double x, double y, int value) {
    final tileSize = getTileSize();
    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;

    // Draw number
    TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: tileSize * 0.6,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      '$value',
      Vector2(centerX, centerY),
      anchor: Anchor.center,
    );
  }

}
