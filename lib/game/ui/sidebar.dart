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
            icon: Icons.trending_flat,
            label: 'Belt (B)',
            tool: Tool.belt,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            context,
            icon: Icons.source,
            label: 'Extractor (E)',
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5A5A8C),
                    Color(0xFF4A4A7C),
                    Color(0xFF3A3A6C),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRotateBelt,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rotate_right,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rotate (R)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
            'B: Belt Tool\nE: Extractor Tool\nR: Rotate Belt\n\nSpace + Drag: Pan\nShift + Drag: Zoom\nScroll: Zoom',
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  const Color(0xFF7C6CEF),
                  const Color(0xFF6C5CE7),
                  const Color(0xFF5B4CD6),
                ]
              : [
                  const Color(0xFF5A5A8C),
                  const Color(0xFF4A4A7C),
                  const Color(0xFF3A3A6C),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF6C5CE7).withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: isSelected ? 12 : 8,
            spreadRadius: isSelected ? 1 : 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFF8C7CEF).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToolSelected(tool),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorButton(BuildContext context, String operator) {
    Tool tool;
    String label;
    String symbol;
    List<Color> gradientColors;
    Color shadowColor;

    switch (operator.toLowerCase()) {
      case 'add':
        tool = Tool.operatorAdd;
        label = 'Add';
        symbol = '+';
        gradientColors = [
          const Color(0xFF66BB6A),
          const Color(0xFF4CAF50),
          const Color(0xFF388E3C),
        ];
        shadowColor = const Color(0xFF4CAF50);
        break;
      case 'subtract':
        tool = Tool.operatorSubtract;
        label = 'Subtract';
        symbol = '-';
        gradientColors = [
          const Color(0xFFEF5350),
          const Color(0xFFF44336),
          const Color(0xFFD32F2F),
        ];
        shadowColor = const Color(0xFFF44336);
        break;
      case 'multiply':
        tool = Tool.operatorMultiply;
        label = 'Multiply';
        symbol = '×';
        gradientColors = [
          const Color(0xFFFFB74D),
          const Color(0xFFFF9800),
          const Color(0xFFF57C00),
        ];
        shadowColor = const Color(0xFFFF9800);
        break;
      case 'divide':
        tool = Tool.operatorDivide;
        label = 'Divide';
        symbol = '÷';
        gradientColors = [
          const Color(0xFF4DD0E1),
          const Color(0xFF00BCD4),
          const Color(0xFF0097A7),
        ];
        shadowColor = const Color(0xFF00BCD4);
        break;
      default:
        return const SizedBox.shrink();
    }

    final isSelected = selectedTool == tool;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? gradientColors
              : gradientColors.map((c) => c.withValues(alpha: 0.7)).toList(),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? shadowColor.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: isSelected ? 12 : 8,
            spreadRadius: isSelected ? 1 : 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToolSelected(tool),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolPreview() {
    String toolName = 'No Tool';
    String directionText = '';
    IconData? icon;

    switch (selectedTool) {
      case Tool.none:
        toolName = 'No Tool Selected';
        icon = Icons.mouse;
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
