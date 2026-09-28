import 'package:android_tile_launcher/model/expression.dart';
import 'package:android_tile_launcher/model/number_format.dart';

const String _operators = '+-*/%^';

// A function or a constant is a word; a function's key types the opening
// bracket with it.
final RegExp _functionAtEnd = RegExp(r'[a-z]+\($');
final RegExp _numberAtEnd = RegExp(r'[0-9.]+$');
final RegExp _plainNumber = RegExp(r'^-?[0-9]*\.?[0-9]+$');

/// What has been keyed into the calculator so far, and what each key does to
/// it. Pure: every key returns the next entry, so the pad has no logic of its
/// own and the rules are testable.
///
/// The keys are the characters of an expression (`7`, `.`, `+`, `(`), a
/// constant (`pi`) or a function with its bracket (`sqrt(`). The pad shows
/// [expression] and, while it can be worked out, [preview]; [equals] replaces
/// it with the answer.
class CalcEntry {
  const CalcEntry({this.expression = '', this.answered = false, this.error});

  final String expression;

  /// True right after [equals]: the expression is an answer. Keying a number,
  /// a bracket, a function or a constant then starts a new sum; keying an
  /// operator carries on from the answer.
  final bool answered;

  /// Why the last [equals] did not work, in the parser's words; cleared by the
  /// next key.
  final String? error;

  bool get isEmpty => expression.isEmpty;

  CalcEntry clear() => const CalcEntry();

  /// Takes back the last key: a whole `sqrt(`, or the last character.
  CalcEntry backspace() {
    if (expression.isEmpty) return this;
    final Match? function = _functionAtEnd.firstMatch(expression);
    final String next = function != null
        ? expression.substring(0, function.start)
        : expression.substring(0, expression.length - 1);
    return CalcEntry(expression: next);
  }

  /// The effect of keying [key]; [this] when the key makes no sense here (a
  /// second `.` in a number, an operator to start with, a `)` with nothing to
  /// close).
  CalcEntry press(String key) {
    if (key.length == 1 && _operators.contains(key)) return _operator(key);
    if (key == '.') return _point();
    if (key == ')') return _close();
    // Digits, `(`, constants and functions: all of them begin something.
    final String base = answered ? '' : expression;
    return CalcEntry(expression: base + key);
  }

  CalcEntry _operator(String op) {
    if (expression.isEmpty) {
      // Only a minus can start an expression.
      return op == '-' ? const CalcEntry(expression: '-') : this;
    }
    final String last = expression[expression.length - 1];
    if (last == '(' || _functionAtEnd.hasMatch(expression)) {
      return op == '-' ? CalcEntry(expression: '$expression-') : this;
    }
    if (_operators.contains(last)) {
      // Two operators in a row: the second replaces the first, except that a
      // minus after `*`, `/`, `%` or `^` is a sign (`2*-3`).
      if (op == '-' && last != '+' && last != '-') {
        return CalcEntry(expression: '$expression-');
      }
      if (expression.length == 1) {
        return op == '-' ? this : const CalcEntry(expression: '-');
      }
      return CalcEntry(
        expression: expression.substring(0, expression.length - 1) + op,
      );
    }
    return CalcEntry(expression: expression + op);
  }

  CalcEntry _point() {
    if (answered) return const CalcEntry(expression: '0.');
    final String last = expression.isEmpty
        ? ''
        : expression[expression.length - 1];
    if (last.isEmpty || !RegExp(r'[0-9.]').hasMatch(last)) {
      return CalcEntry(expression: '${expression}0.');
    }
    final Match? number = _numberAtEnd.firstMatch(expression);
    if (number != null && number.group(0)!.contains('.')) return this;
    return CalcEntry(expression: '$expression.');
  }

  CalcEntry _close() {
    if (expression.isEmpty) return this;
    final int open = '('.allMatches(expression).length;
    final int closed = ')'.allMatches(expression).length;
    if (open <= closed) return this;
    final String last = expression[expression.length - 1];
    if (last == '(' || _operators.contains(last)) return this;
    return CalcEntry(expression: '$expression)');
  }

  /// [expression] with any brackets left open closed, so `2*(3+4` can be
  /// worked out while it is still being keyed.
  String get _closed {
    final int open = '('.allMatches(expression).length;
    final int closed = ')'.allMatches(expression).length;
    return expression + ')' * (open - closed).clamp(0, 1000);
  }

  /// The answer as far as the keys so far give one, or null: nothing keyed,
  /// something unfinished (a trailing operator), an error, or just a number
  /// (which is its own answer).
  String? get preview {
    if (expression.isEmpty || answered) return null;
    final String last = expression[expression.length - 1];
    if (_operators.contains(last) || last == '(') return null;
    if (_plainNumber.hasMatch(expression)) return null;
    try {
      return formatNumber(evaluateExpression(_closed));
    } on ExpressionException {
      return null;
    }
  }

  /// Works the expression out: the answer becomes the expression, or, if it
  /// cannot be, the entry stays and says why in [error].
  CalcEntry equals() {
    if (expression.isEmpty || answered) return this;
    try {
      final double value = evaluateExpression(_closed);
      return CalcEntry(expression: formatNumber(value), answered: true);
    } on ExpressionException catch (problem) {
      return CalcEntry(expression: expression, error: problem.message);
    }
  }
}
