import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';

/// U+00A0 NO-BREAK SPACE — what [MoneyFormatter] joins thousands with.
///
/// Spelled as an escape rather than typed literally, because U+00A0 and a
/// plain U+0020 are indistinguishable in an editor and in a diff, and the
/// difference between them is the whole point: a plain space is bidi class WS
/// and reordered `1 234.56` to `234.56 1` under `ar`/`ur`. See
/// `money_formatter_bidi_test.dart` for the rendering that proved it.
const String nbsp = '\u00A0';

void main() {
  group('MoneyFormatter.format', () {
    test('fiat uses per-currency decimals', () {
      expect(MoneyFormatter.format(1234.5, 'EUR'), '1${nbsp}234.50'); // 2 dp
      expect(MoneyFormatter.format(1000, 'JPY'), '1${nbsp}000'); // 0 decimals
      expect(MoneyFormatter.format(1.234, 'KWD'), '1.234'); // 3 decimals
    });

    test('groups thousands with a no-break space', () {
      expect(
        MoneyFormatter.format(1234567.89, 'USD'),
        '1${nbsp}234${nbsp}567.89',
      );
    });

    test('signed prefixes + only for positive', () {
      expect(MoneyFormatter.format(5, 'EUR', signed: true), '+5.00');
      expect(MoneyFormatter.format(-5, 'EUR', signed: true), '-5.00');
      expect(MoneyFormatter.format(0, 'EUR', signed: true), '0.00');
    });

    test('crypto shows extra precision for tiny values', () {
      // Below 0.01 -> up to 6 places (pattern '#,##0.00####')
      expect(MoneyFormatter.format(0.00001234, 'BTC'), '0.000012');
      // Normal magnitude -> 2 places
      expect(MoneyFormatter.format(1.5, 'BTC'), '1.50');
    });

    test('NaN renders as a dash, not the literal text "NaN"', () {
      // double.nan means "this amount could not be priced in this currency".
      expect(MoneyFormatter.format(double.nan, 'EUR'), '—');
      expect(MoneyFormatter.format(double.nan, 'EUR'), isNot(contains('NaN')));
    });

    test('both infinities render as a dash', () {
      expect(MoneyFormatter.format(double.infinity, 'USD'), '—');
      expect(MoneyFormatter.format(double.negativeInfinity, 'USD'), '—');
    });

    test('the placeholder is not decorated with a sign', () {
      expect(MoneyFormatter.format(double.nan, 'EUR', signed: true), '—');
      expect(MoneyFormatter.format(double.infinity, 'EUR', signed: true), '—');
    });

    test('non-finite handling does not disturb finite values', () {
      expect(MoneyFormatter.format(0, 'EUR'), '0.00');
      expect(MoneyFormatter.format(-1234.5, 'EUR'), '-1${nbsp}234.50');
    });
  });

  group('MoneyFormatter.isUnknown', () {
    test('true only for non-finite values', () {
      expect(MoneyFormatter.isUnknown(double.nan), isTrue);
      expect(MoneyFormatter.isUnknown(double.infinity), isTrue);
      expect(MoneyFormatter.isUnknown(double.negativeInfinity), isTrue);

      expect(MoneyFormatter.isUnknown(0), isFalse);
      expect(MoneyFormatter.isUnknown(-5000), isFalse);
      expect(MoneyFormatter.isUnknown(1e300), isFalse);
    });
  });

  group('MoneyFormatter.decimalsFor', () {
    test('fiat', () {
      expect(MoneyFormatter.decimalsFor('EUR'), 2);
      expect(MoneyFormatter.decimalsFor('JPY'), 0);
      expect(MoneyFormatter.decimalsFor('KWD'), 3);
    });

    test('crypto dynamic', () {
      expect(MoneyFormatter.decimalsFor('BTC', 0.0001), 6);
      expect(MoneyFormatter.decimalsFor('BTC', 5.0), 2);
    });
  });

  group('MoneyFormatter.formatCompact', () {
    // The calendar cells are a seventh of the screen wide and hold two amounts
    // each, inside a FittedBox. A six-figure total did not overflow there — it
    // shrank, so far past its neighbours that it stopped being readable.
    test('anything under four figures is printed in full', () {
      expect(MoneyFormatter.formatCompact(0, 'EUR'), '0.00');
      expect(MoneyFormatter.formatCompact(-87.61, 'EUR'), '-87.61');
      expect(MoneyFormatter.formatCompact(999.99, 'EUR'), '999.99');
    });

    // A month holding a salary put '+1 408.82 EUR' in a cell beside a
    // two-figure expense, and the FittedBox shrank the pair to an unreadable
    // size. Four figures keep every digit that matters and lose the cents.
    test('four figures keep their digits but drop the cents', () {
      expect(
        MoneyFormatter.formatCompact(1408.82, 'EUR'),
        '1${MoneyFormatter.groupSeparator}409',
      );
      expect(
        MoneyFormatter.formatCompact(-1408.82, 'EUR'),
        '-1${MoneyFormatter.groupSeparator}409',
      );
      expect(
        MoneyFormatter.formatCompact(9999.99, 'EUR'),
        '10${MoneyFormatter.groupSeparator}000',
      );
    });

    test('five figures and up are compacted', () {
      expect(MoneyFormatter.formatCompact(109507.73, 'EUR'), '110K');
      expect(MoneyFormatter.formatCompact(-109507.73, 'EUR'), '-110K');
      expect(MoneyFormatter.formatCompact(10000, 'EUR'), '10K');
    });

    test('a non-finite amount stays the unknown placeholder', () {
      expect(
        MoneyFormatter.formatCompact(double.nan, 'EUR'),
        MoneyFormatter.unknownPlaceholder,
      );
    });
  });
}
