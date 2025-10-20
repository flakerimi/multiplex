import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../tool.dart';

class CustomCursor extends StatelessWidget {
  final Offset position;
  final Tool selectedTool;
  final BeltDirection beltDirection;
  final BeltDirection operatorDirection;
  final double? size;

  const CustomCursor({
    super.key,
    required this.position,
    required this.selectedTool,
    required this.beltDirection,
    required this.operatorDirection,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show custom cursor for "none" tool
    if (selectedTool == Tool.none) {
      return const SizedBox.shrink();
    }

    final cursorSize = size ?? 64.0; // Default to 64 if not provided

    // For operators, we need to center the middle tile of the 3-tile preview
    double leftOffset;
    double topOffset;

    if (_isOperatorTool(selectedTool)) {
      final isHorizontal = operatorDirection == BeltDirection.right || operatorDirection == BeltDirection.left;
      if (isHorizontal) {
        // For horizontal operators (A | + | B), center the middle tile
        leftOffset = position.dx - (cursorSize * 1.5); // Center middle tile horizontally
        topOffset = position.dy - (cursorSize / 2); // Center single tile vertically
      } else {
        // For vertical operators, center the middle tile
        leftOffset = position.dx - (cursorSize / 2); // Center single tile horizontally
        topOffset = position.dy - (cursorSize * 1.5); // Center middle tile vertically
      }
    } else {
      // For single-tile tools (belt, extractor), center normally
      final halfSize = cursorSize / 2;
      leftOffset = position.dx - halfSize;
      topOffset = position.dy - halfSize;
    }

    return Positioned(
      left: leftOffset,
      top: topOffset,
      child: IgnorePointer(
        child: _buildCursorWidget(cursorSize),
      ),
    );
  }

  bool _isOperatorTool(Tool tool) {
    return tool == Tool.operatorAdd ||
           tool == Tool.operatorSubtract ||
           tool == Tool.operatorMultiply ||
           tool == Tool.operatorDivide;
  }

  Widget _buildCursorWidget(double cursorSize) {
    switch (selectedTool) {
      case Tool.belt:
        return Transform.rotate(
          angle: _getRotationAngle(),
          child: Container(
            width: cursorSize,
            height: cursorSize,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.yellow, width: 2),
            ),
            child: CustomPaint(
              painter: _BeltArrowPainter(),
            ),
          ),
        );
      case Tool.extractor:
        return Container(
          width: cursorSize,
          height: cursorSize,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Container(
              width: cursorSize * 0.3,
              height: cursorSize * 0.3,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case Tool.operatorAdd:
      case Tool.operatorSubtract:
      case Tool.operatorMultiply:
      case Tool.operatorDivide:
        return _buildOperatorPreview(cursorSize);
      case Tool.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOperatorPreview(double cursorSize) {
    final isHorizontal = operatorDirection == BeltDirection.right || operatorDirection == BeltDirection.left;
    final operatorColor = _getOperatorColor();
    final symbol = _getOperatorSymbol();

    // Use slightly darker/lighter shades for A and B sections (matching render_manager)
    final lightColor = Color.lerp(operatorColor, Colors.white, 0.3)!;
    final darkColor = Color.lerp(operatorColor, Colors.black, 0.2)!;

    if (isHorizontal) {
      // Horizontal layout: | A | + | B |
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOperatorSection(cursorSize, 'A', lightColor, operatorColor),
          _buildOperatorSection(cursorSize, symbol, operatorColor, operatorColor, isSymbol: true),
          _buildOperatorSection(cursorSize, 'B', darkColor, operatorColor),
        ],
      );
    } else {
      // Vertical layout
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOperatorSection(cursorSize, 'A', lightColor, operatorColor),
          _buildOperatorSection(cursorSize, symbol, operatorColor, operatorColor, isSymbol: true),
          _buildOperatorSection(cursorSize, 'B', darkColor, operatorColor),
        ],
      );
    }
  }

  Widget _buildOperatorSection(double size, String label, Color bgColor, Color borderColor, {bool isSymbol = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSymbol ? size * 0.6 : size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getOperatorColor() {
    switch (selectedTool) {
      case Tool.operatorAdd:
        return const Color(0xFF4CAF50); // Green
      case Tool.operatorSubtract:
        return const Color(0xFFF44336); // Red
      case Tool.operatorMultiply:
        return const Color(0xFF9C27B0); // Purple
      case Tool.operatorDivide:
        return const Color(0xFF00BCD4); // Cyan
      default:
        return Colors.grey;
    }
  }

  String _getOperatorSymbol() {
    switch (selectedTool) {
      case Tool.operatorAdd:
        return '+';
      case Tool.operatorSubtract:
        return '-';
      case Tool.operatorMultiply:
        return '×';
      case Tool.operatorDivide:
        return '÷';
      default:
        return '';
    }
  }

  double _getRotationAngle() {
    switch (beltDirection) {
      case BeltDirection.right:
        return 0; // 0 degrees
      case BeltDirection.down:
        return 1.5708; // 90 degrees (π/2)
      case BeltDirection.left:
        return 3.14159; // 180 degrees (π)
      case BeltDirection.up:
        return 4.71239; // 270 degrees (3π/2)
    }
  }
}

class _BeltArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final arrowSize = size.width * 0.3;

    // Draw arrow pointing right (will be rotated by Transform.rotate)
    final path = Path();
    path.moveTo(centerX - arrowSize, centerY - arrowSize);
    path.lineTo(centerX + arrowSize, centerY);
    path.lineTo(centerX - arrowSize, centerY + arrowSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
