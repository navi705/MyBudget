import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';

/// The binary reader used to hand each field's slice to
/// `bytes.buffer.asByteData()`, which is a view of the whole backing buffer
/// rather than of the slice. Offset 0 therefore meant the start of the buffer,
/// so every currency count and every rate after the first was read from the
/// wrong bytes, the parse walked out of step, and a currency code eventually
/// landed on bytes that are not UTF-8:
///
///     FormatException: Missing extension byte (at offset 1)
///
/// Only Android hit it in practice, because debug desktop builds seed from the
/// JSON file instead and never take the binary path.
void main() {
  const history = <String, Map<String, double>>{
    '2024-01-01': {'USD': 1.1042, 'GBP': 0.8612, 'JPY': 160.1234},
    '2024-01-02': {'USD': 1.0951, 'GBP': 0.8677},
    '2024-01-03': {'USD': 1.0903, 'GBP': 0.8701, 'JPY': 158.9, 'CHF': 0.9312},
  };

  Future<Uint8List> writeAndRead(Directory dir) async {
    final path = '${dir.path}/history.bin';
    await CurrencyHistoryBinaryIO.write(path, history);
    return File(path).readAsBytes();
  }

  test('a round trip keeps every date, code and rate', () async {
    final dir = await Directory.systemTemp.createTemp('currency_history');
    addTearDown(() => dir.delete(recursive: true));

    final decoded = CurrencyHistoryBinaryIO.readFromBytes(
      await writeAndRead(dir),
    );

    expect(decoded, history);
  });

  test('bytes that start part way into their buffer decode the same', () async {
    final dir = await Directory.systemTemp.createTemp('currency_history');
    addTearDown(() => dir.delete(recursive: true));
    final bytes = await writeAndRead(dir);

    // What `rootBundle.load` hands back on Android: a view onto a larger
    // buffer, starting at a non-zero offset.
    final padded = Uint8List(bytes.length + 7)
      ..setRange(7, bytes.length + 7, bytes);
    final view = padded.buffer.asUint8List(7, bytes.length);

    expect(CurrencyHistoryBinaryIO.readFromBytes(view), history);
  });

  test('the asset the app ships parses', () {
    // The seeder reads this file on every non-desktop start; a build that
    // bundles a file this reader cannot parse leaves the app with no rates at
    // all and every foreign-currency total unconvertible.
    final bytes = File('lib/data/currency_history.bin').readAsBytesSync();
    final decoded = CurrencyHistoryBinaryIO.readFromBytes(bytes);

    expect(decoded, isNotEmpty);
    final rates = decoded.values.first;
    expect(rates, isNotEmpty);
    expect(rates.values.every((r) => r > 0), isTrue);
  });
}
