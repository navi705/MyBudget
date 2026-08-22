// What a `colorHex` column is allowed to do to a screen: change one swatch.
//
// The value is plain text that arrives from sync, from a CSV import and from
// hand-edited exports, and six of the seven screens that read it ended in a
// bare `int.parse`. That throws `FormatException` from inside `build()`, so a
// single unreadable style took out the entire list it appeared in.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/hex_color.dart';

void main() {
  const fallback = Colors.orange;
  Color parse(String? hex) => parseHexColor(hex, fallback: fallback);

  test('reads the four shapes the app writes', () {
    expect(parse('#FF5733'), const Color(0xFFFF5733));
    expect(parse('FF5733'), const Color(0xFFFF5733));
    expect(parse('#80FF5733'), const Color(0x80FF5733));
    expect(parse('80FF5733'), const Color(0x80FF5733));
  });

  test('is case insensitive', () {
    expect(parse('#ff5733'), const Color(0xFFFF5733));
  });

  test('an eight-character string that is not hex falls back', () {
    // The length check the old copies had let this straight through to
    // `int.parse`, which is where the screen died.
    expect(parse('ZZZZZZZZ'), fallback);
    expect(parse('#notahex'), fallback);
  });

  test('an empty hex falls back instead of parsing "0x"', () {
    // Three copies had no length check at all, so a style with a blank colour
    // threw on every build.
    expect(parse(''), fallback);
    expect(parse('#'), fallback);
  });

  test('a null hex falls back', () {
    expect(parse(null), fallback);
  });

  test('a wrong-length hex falls back', () {
    expect(parse('#FFF'), fallback);
    expect(parse('#FF57331'), fallback);
    expect(parse('#FF5733112233'), fallback);
  });

  test('a signed or separated number is not a colour', () {
    // `int.parse('0x$hex')` accepted both of these, so they became colours
    // nothing had ever written.
    expect(parse('-1234567'), fallback);
    expect(parse('1_234567'), fallback);
  });

  test('surrounding whitespace is tolerated', () {
    expect(parse('  #FF5733  '), const Color(0xFFFF5733));
  });

  test('the fallback is the caller\'s, not one shared grey', () {
    // Each screen had its own default and they differ on purpose: an account
    // swatch falls back to orange, an icon to grey.
    expect(parseHexColor('nope', fallback: Colors.grey), Colors.grey);
    expect(parseHexColor('nope', fallback: Colors.orange), Colors.orange);
  });
}
