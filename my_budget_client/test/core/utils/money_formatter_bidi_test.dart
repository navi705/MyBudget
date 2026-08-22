// Every balance over 999 used to be stated wrong in Arabic and Urdu.
//
// `MoneyFormatter.format` grouped thousands with a plain U+0020. That
// character is bidi class WS, and the Unicode bidi algorithm resolves a
// whitespace neutral sitting between two European-number runs to the paragraph
// direction (N1 treats EN as R). Under an RTL paragraph the separator became an
// RTL run splitting the number in two, and the reordering pass then swapped the
// halves: an account holding `1 234.56` was painted `234.56 1`. The app was
// telling a reader a different number than the one it held.
//
// U+00A0 NO-BREAK SPACE is bidi class CS, and rule W4 folds a single common
// separator between two numbers of the same type into that type. The whole
// amount stays one run, and one run cannot be reordered against itself.
//
// Grouping is only half of it. Once an amount is glued to a currency code or
// dropped into a translated sentence, the letters beside it decide the run
// direction and the amount can still be flipped past them, so anything
// embedded goes through LRI…PDI as well.
//
// The string tests below assert on code units, because U+0020 and U+00A0 are
// indistinguishable on screen and in a diff. The widget tests assert on the
// geometry of the painted glyphs in a real RTL paragraph, and each one carries
// a control built the old way — proof that the assertion can still fail.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';

/// U+00A0 NO-BREAK SPACE — what the groups are joined with now.
const String nbsp = '\u00A0';

/// U+0020 SPACE — what they used to be joined with, and the bug.
const int spaceCodeUnit = 0x0020;

/// U+2066 LEFT-TO-RIGHT ISOLATE / U+2069 POP DIRECTIONAL ISOLATE.
const String lri = '\u2066';
const String pdi = '\u2069';

/// Lays [text] out in an RTL paragraph and reports where the glyphs for
/// `text.substring(start, end)` were painted.
///
/// Reading boxes back off the `RenderParagraph` is the only assertion that
/// speaks about what a reader actually sees: the *string* is the same either
/// way, and only the layout tells a correct number from a scrambled one.
Future<Rect> _boxOf(
  WidgetTester tester,
  String text,
  int start,
  int end,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Center(child: Text(text)),
    ),
  );

  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  expect(boxes, isNotEmpty, reason: 'no glyphs laid out for [$start, $end)');

  return boxes
      .map((box) => box.toRect())
      .reduce((a, b) => a.expandToInclude(b));
}

void main() {
  group('the group separator', () {
    test('is U+00A0, never a plain space', () {
      final formatted = MoneyFormatter.format(1234.56, 'USD');

      expect(formatted, '1${nbsp}234.56');
      expect(formatted.codeUnits, contains(0x00A0));
      expect(
        formatted.codeUnits,
        isNot(contains(spaceCodeUnit)),
        reason: 'a plain space here reorders the number under ar and ur',
      );
    });

    test('every group of a multi-group amount is joined the same way', () {
      final formatted = MoneyFormatter.format(1234567.89, 'USD');

      expect(formatted, '1${nbsp}234${nbsp}567.89');
      expect(
        formatted.codeUnits.where((unit) => unit == 0x00A0).length,
        2,
        reason: 'both separators have to survive, not only the first',
      );
      expect(formatted.codeUnits, isNot(contains(spaceCodeUnit)));
    });

    test('the zero- and three-decimal patterns group the same way', () {
      expect(MoneyFormatter.format(1000, 'JPY'), '1${nbsp}000');
      expect(MoneyFormatter.format(1234.567, 'KWD'), '1${nbsp}234.567');
      expect(
        MoneyFormatter.format(-1234.5, 'EUR'),
        '-1${nbsp}234.50',
        reason: 'a negative amount is grouped like any other',
      );
    });

    test('it is a constant, so callers can join with the same character', () {
      expect(MoneyFormatter.groupSeparator, nbsp);
      expect(MoneyFormatter.groupSeparator.codeUnits, <int>[0x00A0]);
    });

    test('en and ru are unchanged apart from the separator itself', () {
      // The visual contract of the fix: same digits, same order, same count of
      // characters, and U+00A0 paints exactly as wide as the space it replaced.
      final formatted = MoneyFormatter.format(1234567.89, 'USD');

      expect(formatted.replaceAll(nbsp, ' '), '1 234 567.89');
      expect(formatted.length, '1 234 567.89'.length);
    });
  });

  group('bidi isolation', () {
    test('isolate wraps its argument in LRI…PDI', () {
      expect(MoneyFormatter.isolate('1${nbsp}234'), '${lri}1${nbsp}234$pdi');
    });

    test('formatIsolated is format, isolated', () {
      expect(
        MoneyFormatter.formatIsolated(1234.56, 'USD'),
        '${lri}1${nbsp}234.56$pdi',
      );
    });

    test('formatWithSymbol puts amount and symbol inside one isolate', () {
      expect(
        MoneyFormatter.formatWithSymbol(1234.56, 'USD', r'$'),
        '${lri}1${nbsp}234.56$nbsp\$$pdi',
      );
    });

    test('a direction glyph sits inside the isolate, against the digits', () {
      final text = MoneyFormatter.formatWithSymbol(
        1234.56,
        'USD',
        r'$',
        prefix: '\u2212',
      );

      expect(text, '$lri\u22121${nbsp}234.56$nbsp\$$pdi');
      expect(
        text.indexOf('\u2212'),
        greaterThan(text.indexOf(lri)),
        reason: 'a glyph outside the isolate can drift away from its number',
      );
    });

    test('the unknown placeholder is not given a direction glyph', () {
      // '—' means "this could not be priced". A minus in front of it would
      // state a direction for a figure the app does not have.
      expect(
        MoneyFormatter.formatWithSymbol(
          double.nan,
          'USD',
          r'$',
          prefix: '\u2212',
        ),
        '$lri${MoneyFormatter.unknownPlaceholder}$nbsp\$$pdi',
      );
    });
  });

  group('painted in a right-to-left paragraph', () {
    testWidgets('the digit groups keep their order', (tester) async {
      final text = MoneyFormatter.format(1234.56, 'USD');
      expect(text, '1${nbsp}234.56');

      // Index 0 is the thousands digit; 2 onwards is the rest of the number.
      final thousands = await _boxOf(tester, text, 0, 1);
      final remainder = await _boxOf(tester, text, 2, text.length);

      expect(
        thousands.left,
        lessThan(remainder.left),
        reason: 'the 1 of "1 234.56" has to be painted left of the 234.56',
      );
    });

    testWidgets('control: a plain space reverses them', (tester) async {
      // Not an assertion about the product — an assertion that the test above
      // measures the thing that was broken. Were Flutter to stop reordering
      // this, the test above would start passing for a reason unrelated to the
      // separator, and this one would catch that.
      const text = '1 234.56';

      final thousands = await _boxOf(tester, text, 0, 1);
      final remainder = await _boxOf(tester, text, 2, text.length);

      expect(
        thousands.left,
        greaterThan(remainder.left),
        reason:
            'U+0020 is exactly what put the thousands group on the '
            'wrong side, and this is the rendering that proved it',
      );
    });

    testWidgets('an isolated amount stays in front of its currency code', (
      tester,
    ) async {
      // Groups intact is not enough: without the isolate the whole amount is
      // flipped past the letters beside it.
      final text = MoneyFormatter.formatWithSymbol(1234.56, 'USD', 'USD');
      final digits = text.indexOf('1');
      final code = text.indexOf('USD');

      final amountBox = await _boxOf(tester, text, digits, digits + 1);
      final codeBox = await _boxOf(tester, text, code, code + 3);

      expect(
        amountBox.left,
        lessThan(codeBox.left),
        reason: 'the reader has to meet the number before its currency',
      );
    });

    testWidgets('control: without the isolate the code overtakes the amount', (
      tester,
    ) async {
      final text = '${MoneyFormatter.format(1234.56, 'USD')} USD';
      final digits = text.indexOf('1');
      final code = text.indexOf('USD');

      final amountBox = await _boxOf(tester, text, digits, digits + 1);
      final codeBox = await _boxOf(tester, text, code, code + 3);

      expect(
        amountBox.left,
        greaterThan(codeBox.left),
        reason: 'this is the reordering LRI…PDI exists to prevent',
      );
    });
  });
}
