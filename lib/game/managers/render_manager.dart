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

    final paint = Paint()
      ..color = tile.getColor()
      ..style = PaintingStyle.fill;

    final screenX = x * tileSize - gridOffset.x;
    final screenY = y * tileSize - gridOffset.y;

    canvas.drawRect(
      Rect.fromLTWH(screenX, screenY, tileSize, tileSize),
      paint,
    );

    // Draw belt arrow
    if (tile.type == TileType.belt && tile.beltDirection != null) {
      _drawBeltArrow(canvas, screenX, screenY, tile.beltDirection!);

      // Draw carrying number on belt
      if (tile.carryingNumber != null) {
        _drawNumberValue(canvas, screenX, screenY, tile.carryingNumber!);
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

    // Draw operator symbol
    if (tile.type == TileType.operator && tile.operatorType != null) {
      _drawOperatorSymbol(canvas, screenX, screenY, tile.operatorType!);
    }
  }

  void _drawBeltArrow(Canvas canvas, double x, double y, BeltDirection direction) {
    final tileSize = getTileSize();
    final arrowPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;
    final arrowSize = tileSize * 0.3;

    final path = Path();
    switch (direction) {
      case BeltDirection.right:
        path.moveTo(centerX - arrowSize, centerY - arrowSize);
        path.lineTo(centerX + arrowSize, centerY);
        path.lineTo(centerX - arrowSize, centerY + arrowSize);
        break;
      case BeltDirection.left:
        path.moveTo(centerX + arrowSize, centerY - arrowSize);
        path.lineTo(centerX - arrowSize, centerY);
        path.lineTo(centerX + arrowSize, centerY + arrowSize);
        break;
      case BeltDirection.down:
        path.moveTo(centerX - arrowSize, centerY - arrowSize);
        path.lineTo(centerX, centerY + arrowSize);
        path.lineTo(centerX + arrowSize, centerY - arrowSize);
        break;
      case BeltDirection.up:
        path.moveTo(centerX - arrowSize, centerY + arrowSize);
        path.lineTo(centerX, centerY - arrowSize);
        path.lineTo(centerX + arrowSize, centerY + arrowSize);
        break;
    }

    canvas.drawPath(path, arrowPaint);
  }

  void _drawExtractorIcon(Canvas canvas, double x, double y, int? extractValue) {
    final tileSize = getTileSize();
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;
    final iconSize = tileSize * 0.4;

    // Draw a simple circle for extractor
    canvas.drawCircle(Offset(centerX, centerY), iconSize, iconPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(centerX, centerY), iconSize, borderPaint);

    // Draw extract value if present
    if (extractValue != null) {
      TextPaint(
        style: TextStyle(
          color: Colors.black,
          fontSize: tileSize * 0.3,
          fontWeight: FontWeight.bold,
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

    final double startX = (visibleRect.left + gridOffset.x) ~/ tileSize * tileSize;
    final double startY = (visibleRect.top + gridOffset.y) ~/ tileSize * tileSize;
    final double endX = (visibleRect.right + gridOffset.x) ~/ tileSize * tileSize + tileSize;
    final double endY = (visibleRect.bottom + gridOffset.y) ~/ tileSize * tileSize + tileSize;

    // Draw vertical grid lines
    for (double x = startX; x <= endX; x += tileSize) {
      canvas.drawLine(
        Offset(x - gridOffset.x, 0),
        Offset(x - gridOffset.x, visibleRect.bottom),
        paint,
      );
    }

    // Draw horizontal grid lines
    for (double y = startY; y <= endY; y += tileSize) {
      canvas.drawLine(
        Offset(0, y - gridOffset.y),
        Offset(visibleRect.right, y - gridOffset.y),
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

  void drawViewportBorder(Canvas canvas, Rect visibleRect) {
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, visibleRect.width, visibleRect.height),
      borderPaint,
    );
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

  void _drawOperatorSymbol(Canvas canvas, double x, double y, OperatorType operatorType) {
    final tileSize = getTileSize();
    final centerX = x + tileSize / 2;
    final centerY = y + tileSize / 2;

    String symbol;
    switch (operatorType) {
      case OperatorType.add:
        symbol = '+';
        break;
      case OperatorType.subtract:
        symbol = '-';
        break;
      case OperatorType.multiply:
        symbol = '×';
        break;
      case OperatorType.divide:
        symbol = '÷';
        break;
    }

    // Draw operator symbol
    TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: tileSize * 0.6,
        fontWeight: FontWeight.bold,
      ),
    ).render(
      canvas,
      symbol,
      Vector2(centerX, centerY),
      anchor: Anchor.center,
    );
  }
}
