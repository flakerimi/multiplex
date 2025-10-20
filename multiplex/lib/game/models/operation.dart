import 'dart:ui';

class Operation {
  final String symbol;
  final OperationType type;
  final Color color;
  final int value;

  const Operation({
    required this.symbol,
    required this.type,
    required this.color,
    required this.value,
  });

  double execute(double a, double b) {
    switch (symbol) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b != 0 ? a / b : 0;
      default:
        return 0;
    }
  }

  static const Operation add = Operation(
    symbol: '+',
    type: OperationType.operator,
    color: Color(0xFFFFAA00),
    value: 0,
  );

  static const Operation subtract = Operation(
    symbol: '-',
    type: OperationType.operator,
    color: Color(0xFFFFAA00),
    value: 0,
  );

  static const Operation multiply = Operation(
    symbol: '×',
    type: OperationType.operator,
    color: Color(0xFFFFAA00),
    value: 0,
  );

  static const Operation divide = Operation(
    symbol: '÷',
    type: OperationType.operator,
    color: Color(0xFFFFAA00),
    value: 0,
  );

  static Operation number(int num) => Operation(
        symbol: num.toString(),
        type: OperationType.number,
        color: Color(0xFFAA3333),
        value: num,
      );
}

enum OperationType { number, operator }
