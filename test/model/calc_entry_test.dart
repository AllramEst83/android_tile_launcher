import 'package:android_tile_launcher/model/calc_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// The entry after keying each of [keys] in turn.
CalcEntry _keyed(List<String> keys, [CalcEntry start = const CalcEntry()]) =>
    keys.fold(start, (CalcEntry entry, String key) => entry.press(key));

void main() {
  group('keying a sum', () {
    test('digits and operators build the expression', () {
      expect(_keyed(<String>['2', '+', '3', '*', '4']).expression, '2+3*4');
    });

    test('a number can have one decimal point', () {
      expect(_keyed(<String>['1', '.', '5', '.', '2']).expression, '1.52');
      expect(
        _keyed(<String>['1', '.', '5', '+', '2', '.', '5']).expression,
        '1.5+2.5',
      );
    });

    test('a point with nothing before it starts 0.', () {
      expect(_keyed(<String>['.']).expression, '0.');
      expect(_keyed(<String>['2', '+', '.', '5']).expression, '2+0.5');
    });

    test('an operator cannot start an expression, except a minus', () {
      expect(_keyed(<String>['+']).expression, '');
      expect(_keyed(<String>['*']).expression, '');
      expect(_keyed(<String>['-']).expression, '-');
    });

    test('a second operator replaces the first', () {
      expect(_keyed(<String>['2', '+', '*', '3']).expression, '2*3');
      expect(_keyed(<String>['2', '*', '+', '3']).expression, '2+3');
    });

    test('a minus after * / % or ^ is a sign', () {
      expect(_keyed(<String>['2', '*', '-', '3']).expression, '2*-3');
      expect(_keyed(<String>['2', '^', '-', '1']).expression, '2^-1');
    });

    test('a minus after a plus or minus replaces it', () {
      expect(_keyed(<String>['2', '+', '-', '3']).expression, '2-3');
    });

    test('a minus is allowed straight after an opening bracket', () {
      expect(_keyed(<String>['(', '-', '3']).expression, '(-3');
      expect(_keyed(<String>['sqrt(', '-']).expression, 'sqrt(-');
      expect(_keyed(<String>['(', '+']).expression, '(');
    });

    test('a closing bracket needs one to close, and something inside it', () {
      expect(_keyed(<String>[')']).expression, '');
      expect(_keyed(<String>['(', ')']).expression, '(');
      expect(_keyed(<String>['(', '2', '+', ')']).expression, '(2+');
      expect(_keyed(<String>['(', '2', ')']).expression, '(2)');
      expect(_keyed(<String>['(', '2', ')', ')']).expression, '(2)');
    });

    test('functions and constants are typed whole', () {
      expect(_keyed(<String>['sqrt(', '1', '6', ')']).expression, 'sqrt(16)');
      expect(_keyed(<String>['2', '*', 'pi']).expression, '2*pi');
    });
  });

  group('taking a key back', () {
    test('removes the last character', () {
      expect(_keyed(<String>['1', '2']).backspace().expression, '1');
    });

    test('removes a whole function with its bracket', () {
      expect(_keyed(<String>['2', '+', 'sqrt(']).backspace().expression, '2+');
    });

    test('on nothing, does nothing', () {
      expect(const CalcEntry().backspace().expression, '');
    });

    test('clear empties it, error and all', () {
      final CalcEntry failed = _keyed(<String>['1', '/', '0']).equals();

      expect(failed.error, isNotNull);
      expect(failed.clear().expression, '');
      expect(failed.clear().error, isNull);
    });
  });

  group('the answer so far', () {
    test('appears once there is something to work out', () {
      expect(_keyed(<String>['2', '+', '3']).preview, '5');
      expect(_keyed(<String>['2', '*', '(', '3', '+', '4']).preview, '14');
    });

    test('closes brackets left open', () {
      expect(_keyed(<String>['sqrt(', '1', '6']).preview, '4');
    });

    test('is not shown for a bare number, nothing, or an unfinished sum', () {
      expect(_keyed(<String>['4', '2']).preview, isNull);
      expect(const CalcEntry().preview, isNull);
      expect(_keyed(<String>['2', '+']).preview, isNull);
      expect(_keyed(<String>['2', '*', '(']).preview, isNull);
      expect(_keyed(<String>['-', '5']).preview, isNull);
    });

    test('is not shown when the sum cannot be worked out', () {
      expect(_keyed(<String>['1', '/', '0']).preview, isNull);
    });

    test('is tidy: 0.1 + 0.2 is 0.3', () {
      expect(
        _keyed(<String>['0', '.', '1', '+', '0', '.', '2']).preview,
        '0.3',
      );
    });
  });

  group('equals', () {
    test('the answer becomes the expression', () {
      final CalcEntry answer = _keyed(<String>['2', '+', '3', '*', '4'])
          .equals();

      expect(answer.expression, '14');
      expect(answer.answered, isTrue);
      expect(answer.preview, isNull);
    });

    test('closes brackets left open', () {
      expect(
        _keyed(<String>['2', '*', '(', '3', '+', '4']).equals().expression,
        '14',
      );
    });

    test('a sum that cannot be worked out stays, and says why', () {
      final CalcEntry failed = _keyed(<String>['1', '/', '0']).equals();

      expect(failed.expression, '1/0');
      expect(failed.error, 'division by zero');
      expect(failed.answered, isFalse);
    });

    test('the next key clears the error and carries on', () {
      final CalcEntry failed = _keyed(<String>['1', '/', '0']).equals();

      final CalcEntry next = failed.backspace();

      expect(next.error, isNull);
      expect(next.expression, '1/');
    });

    test('on an empty or already answered entry does nothing', () {
      expect(const CalcEntry().equals().expression, '');
      final CalcEntry answer = _keyed(<String>['2', '+', '2']).equals();
      expect(answer.equals(), same(answer));
    });
  });

  group('after an answer', () {
    CalcEntry answer() => _keyed(<String>['2', '+', '3']).equals();

    test('an operator carries on from it', () {
      expect(_keyed(<String>['*', '4'], answer()).expression, '5*4');
      expect(_keyed(<String>['*', '4'], answer()).answered, isFalse);
    });

    test('a digit, a bracket, a function or a constant starts a new sum', () {
      expect(_keyed(<String>['7'], answer()).expression, '7');
      expect(_keyed(<String>['('], answer()).expression, '(');
      expect(_keyed(<String>['sqrt('], answer()).expression, 'sqrt(');
      expect(_keyed(<String>['pi'], answer()).expression, 'pi');
    });

    test('a point starts 0.', () {
      expect(_keyed(<String>['.'], answer()).expression, '0.');
    });

    test('a negative answer can be carried on from', () {
      final CalcEntry negative = _keyed(<String>['2', '-', '5']).equals();

      expect(negative.expression, '-3');
      expect(_keyed(<String>['*', '2'], negative).equals().expression, '-6');
    });
  });

  test('big and small answers stay workable', () {
    final CalcEntry big = _keyed(<String>['9', '9', '^', '9']).equals();

    // A long answer is shown in exponent form and can be carried on from.
    expect(big.error, isNull);
    expect(_keyed(<String>['/', '2'], big).equals().error, isNull);
  });
}
