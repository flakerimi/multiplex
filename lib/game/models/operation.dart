enum Operation {
  add,
  subtract,
  multiply,
  divide;

  String get symbol {
    switch (this) {
      case Operation.add:
        return 'a + b';
      case Operation.subtract:
        return 'a - b';
      case Operation.multiply:
        return 'a × b';
      case Operation.divide:
        return 'a ÷ b';
    }
  }

  double execute(double a, double b) {
    switch (this) {
      case Operation.add:
        return a + b;
      case Operation.subtract:
        return a - b;
      case Operation.multiply:
        return a * b;
      case Operation.divide:
        return b != 0 ? a / b : double.infinity;
    }
  }
}
