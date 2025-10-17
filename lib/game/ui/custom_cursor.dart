import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../tool.dart';

class CustomCursor extends StatelessWidget {
  final Offset position;
  final Tool selectedTool;
  final BeltDirection beltDirection;
  final double? size;

  const CustomCursor({
    super.key,
    required this.position,
    required this.selectedTool,
    required this.beltDirection,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show custom cursor for "none" tool
    if (selectedTool == Tool.none) {
      return const SizedBox.shrink();
    }

    final cursorSize = size ?? 64.0; // Default to 64 if not provided
    final halfSize = cursorSize / 2;

    return Positioned(
      left: position.dx - halfSize, // Center the cursor
      top: position.dy - halfSize,
      child: IgnorePointer(
        child: _buildCursorWidget(cursorSize),
      ),
    );
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
        return Container(
          width: cursorSize,
          height: cursorSize,
          decoration: BoxDecoration(
            color: _getOperatorColor().withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              _getOperatorSymbol(),
              style: TextStyle(
                color: Colors.white,
                fontSize: cursorSize * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case Tool.none:
        return const SizedBox.shrink();
    }
  }

  Color _getOperatorColor() {
    switch (selectedTool) {
      case Tool.operatorAdd:
        return Colors.green;
      case Tool.operatorSubtract:
        return Colors.red;
      case Tool.operatorMultiply:
        return Colors.orange;
      case Tool.operatorDivide:
        return Colors.teal;
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
