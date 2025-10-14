import 'package:flutter/material.dart';

import '../models/tile.dart';
import '../tool.dart';

class Sidebar extends StatelessWidget {
  final Tool selectedTool;
  final Function(Tool) onToolSelected;
  final VoidCallback onRotateBelt;
  final List<String> unlockedOperators;
  final BeltDirection beltDirection;
  final BeltDirection operatorDirection;

  const Sidebar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
    required this.onRotateBelt,
    this.unlockedOperators = const [],
    this.beltDirection = BeltDirection.right,
    this.operatorDirection = BeltDirection.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF2C2C54),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildToolButton(
            context,
            icon: Icons.pan_tool,
            label: 'Pan (1)',
            tool: Tool.none,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            context,
            icon: Icons.trending_flat,
            label: 'Belt (2)',
            tool: Tool.belt,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            context,
            icon: Icons.source,
            label: 'Extractor (3)',
            tool: Tool.extractor,
          ),
          // Show unlocked operators
          ...unlockedOperators.map((op) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildOperatorButton(context, op),
            );
          }),
          if (selectedTool == Tool.belt) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRotateBelt,
              icon: const Icon(Icons.rotate_right),
              label: const Text('Rotate (R)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4A7C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const Spacer(),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          // Tool Preview
          _buildToolPreview(),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          const Text(
            'Controls:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Space + Drag: Pan\nShift + Drag: Zoom\nScroll: Zoom',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Tool tool,
  }) {
    final isSelected = selectedTool == tool;

    return ElevatedButton.icon(
      onPressed: () => onToolSelected(tool),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF6C5CE7)
            : const Color(0xFF4A4A7C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildOperatorButton(BuildContext context, String operator) {
    Tool tool;
    String label;
    String symbol;

    switch (operator.toLowerCase()) {
      case 'add':
        tool = Tool.operatorAdd;
        label = 'Add';
        symbol = '+';
        break;
      case 'subtract':
        tool = Tool.operatorSubtract;
        label = 'Subtract';
        symbol = '-';
        break;
      case 'multiply':
        tool = Tool.operatorMultiply;
        label = 'Multiply';
        symbol = '×';
        break;
      case 'divide':
        tool = Tool.operatorDivide;
        label = 'Divide';
        symbol = '÷';
        break;
      default:
        return const SizedBox.shrink();
    }

    final isSelected = selectedTool == tool;

    return ElevatedButton(
      onPressed: () => onToolSelected(tool),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFFE74C3C) // Red highlight for operators
            : const Color(0xFF8E44AD), // Purple for operators
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            symbol,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildToolPreview() {
    String toolName = 'None';
    String directionText = '';
    IconData? icon;

    switch (selectedTool) {
      case Tool.none:
        toolName = 'Pan Mode';
        icon = Icons.pan_tool;
        break;
      case Tool.belt:
        toolName = 'Belt';
        icon = Icons.trending_flat;
        directionText = _getDirectionText(beltDirection);
        break;
      case Tool.extractor:
        toolName = 'Extractor';
        icon = Icons.source;
        break;
      case Tool.operatorAdd:
        toolName = 'Add Operator';
        directionText = _getDirectionText(operatorDirection);
        break;
      case Tool.operatorSubtract:
        toolName = 'Subtract Operator';
        directionText = _getDirectionText(operatorDirection);
        break;
      case Tool.operatorMultiply:
        toolName = 'Multiply Operator';
        directionText = _getDirectionText(operatorDirection);
        break;
      case Tool.operatorDivide:
        toolName = 'Divide Operator';
        directionText = _getDirectionText(operatorDirection);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6C5CE7), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Tool:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null)
                Icon(icon, color: Colors.white, size: 20),
              if (icon != null)
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  toolName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (directionText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_forward, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  directionText,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getDirectionText(BeltDirection direction) {
    switch (direction) {
      case BeltDirection.up:
        return 'Direction: ↑ Up';
      case BeltDirection.down:
        return 'Direction: ↓ Down';
      case BeltDirection.left:
        return 'Direction: ← Left';
      case BeltDirection.right:
        return 'Direction: → Right';
    }
  }
}
