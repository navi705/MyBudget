import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';

/// The two currency-history decodes on the startup path - a 6.86 MB
/// `jsonDecode` and a 2.23 MB gzip-plus-byte-walk - used to run on whichever
/// isolate called them, which is the UI isolate: they were reached from
/// `IntilizationData.fetchApiDataInBackground()`, and *not awaiting* something
/// takes it off the critical path, not off the isolate. Both now go through
/// `compute`.
///
/// So these tests check the two things that move can break:
///
///  * the parsed result is byte-for-byte what the old inline code produced, and
///  * the payload actually survives the isolate port (a closure, a repository
///    or a database handle in either direction throws at the boundary, not at
///    compile time).
void main() {
  /// The decode exactly as it stood inline in `getCurrenciesInitial`, before
  /// it was lifted into `parseCurrencyHistoryMap`. Kept verbatim so the
  /// equality below means something.
  Map<String, Map<String, double>> legacyJsonParse(String content) {
    final fileHistoryMap = <String, Map<String, double>>{};
    final jsonMap = jsonDecode(content);
    if (jsonMap is Map) {
      jsonMap.forEach((k, v) {
        if (v is Map) {
          Map<String, double> rates = {};
          v.forEach((curr, rate) {
            if (rate is num) {
              rates[curr.toString().toUpperCase()] = rate.toDouble();
            }
          });
          fileHistoryMap[k.toString()] = rates;
        }
      });
    }
    return fileHistoryMap;
  }

  const fixture = '''
{
  "2024-04-01": { "usd": 1.0785, "gbp": 0.85394, "jpy": 163.31 },
  "2024-04-02": { "usd": 1.0768, "gbp": 0.8551 },
  "2024-04-03": { "USD": 1.0837, "chf": 0.97655, "btc": 0.0000158 },
  "_broken_rate": { "usd": "not a number", "gbp": 0.85 },
  "_not_a_map": 42
}
''';

  final fixtureBytes = Uint8List.fromList(utf8.encode(fixture));

  group('JSON history', () {
    test('the new parse matches the old inline decode', () {
      expect(parseCurrencyHistoryMap(fixtureBytes), legacyJsonParse(fixture));
    });

    test('it keeps the old behaviours the equality above depends on', () {
      final parsed = parseCurrencyHistoryMap(fixtureBytes);

      // Codes are upper-cased. Not cosmetic: on debug desktop this map is
      // written back over the developer's history file in step 5 of
      // getCurrenciesInitial, so normalising differently would rewrite it.
      expect(parsed['2024-04-01']!.keys, ['USD', 'GBP', 'JPY']);
      // A non-num rate is dropped, its day is kept.
      expect(parsed['_broken_rate'], {'GBP': 0.85});
      // A day whose value is not a map is dropped entirely.
      expect(parsed.containsKey('_not_a_map'), isFalse);
    });

    test('the same bytes parse identically through compute()', () async {
      // The real regression risk of the change: `compute` needs a top-level
      // function and a transferable payload in both directions. `Uint8List` in,
      // a map of Strings and doubles out - nothing holding a repository.
      final viaIsolate = await compute(parseCurrencyHistoryMap, fixtureBytes);

      expect(viaIsolate, parseCurrencyHistoryMap(fixtureBytes));
    });

    test('malformed JSON throws rather than returning half a history', () {
      // getCurrenciesInitial's outer catch is what handled this before, and
      // still is. Swallowing it here would seed a partial history instead.
      expect(
        () =>
            parseCurrencyHistoryMap(Uint8List.fromList(utf8.encode('{ oops'))),
        throwsFormatException,
      );
    });
  });

  group('binary history', () {
    const history = <String, Map<String, double>>{
      '2024-04-01': {'USD': 1.0785, 'GBP': 0.85394, 'JPY': 163.31},
      '2024-04-02': {'USD': 1.0768, 'GBP': 0.8551},
      '2024-04-03': {'USD': 1.0837, 'CHF': 0.97655, 'BTC': 0.0000158},
    };

    Future<Uint8List> writeAndRead(Map<String, Map<String, double>> h) async {
      final dir = await Directory.systemTemp.createTemp('currency_isolate');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/history.bin';
      await CurrencyHistoryBinaryIO.write(path, h);
      return File(path).readAsBytes();
    }

    test('readFromBytesInIsolate matches readFromBytes', () async {
      final bytes = await writeAndRead(history);

      expect(
        await CurrencyHistoryBinaryIO.readFromBytesInIsolate(bytes),
        CurrencyHistoryBinaryIO.readFromBytes(bytes),
      );
      expect(
        await CurrencyHistoryBinaryIO.readFromBytesInIsolate(bytes),
        history,
      );
    });

    test(
      'a view starting part way into its buffer survives the port',
      () async {
        // What `rootBundle.load` hands back on Android, and what the call site
        // now posts across the isolate boundary.
        final bytes = await writeAndRead(history);
        final padded = Uint8List(bytes.length + 7)
          ..setRange(7, bytes.length + 7, bytes);
        final view = padded.buffer.asUint8List(7, bytes.length);

        expect(
          await CurrencyHistoryBinaryIO.readFromBytesInIsolate(view),
          history,
        );
      },
    );

    test('a non-ASCII code still round-trips', () async {
      // The reader interns codes and builds them with `String.fromCharCodes`
      // when every byte is ASCII. Anything above 0x7F has to fall back to the
      // real UTF-8 decoder rather than be split into mojibake bytes.
      const exotic = <String, Map<String, double>>{
        '2024-04-01': {'USD': 1.0785, 'ЕВРО': 1.0, 'Ω': 2.5},
      };

      expect(
        CurrencyHistoryBinaryIO.readFromBytes(await writeAndRead(exotic)),
        exotic,
      );
    });

    test('the seeder parse survives the port with its rows intact', () async {
      // getCurrenciesRateToSeeder's release branch, which drift's onCreate
      // reaches on the UI isolate on a first launch. It now returns
      // List<ExchangeRateDomain> across a compute() boundary, so the domain
      // objects themselves have to be sendable - a field holding a repository
      // or a database handle would throw here and nowhere earlier.
      final bytes = await writeAndRead(history);

      final viaIsolate = await compute(parseCurrencyHistoryBinary, bytes);
      final direct = parseCurrencyHistoryBinary(bytes);

      expect(viaIsolate.length, direct.length);
      expect(viaIsolate.length, 8); // 3 + 2 + 3 rates
      for (var i = 0; i < direct.length; i++) {
        expect(viaIsolate[i].fromCurrencyCode, direct[i].fromCurrencyCode);
        expect(viaIsolate[i].toCurrencyCode, direct[i].toCurrencyCode);
        expect(viaIsolate[i].rate, direct[i].rate);
        expect(viaIsolate[i].date, direct[i].date);
        expect(viaIsolate[i].preset, direct[i].preset);
      }
    });

    test('interning does not confuse two distinct codes', () async {
      // The intern cache is keyed by the code's bytes packed into an int, not
      // by a hash, precisely so two codes can never collide and file one
      // currency's rates under another's name.
      const many = <String, Map<String, double>>{
        '2024-04-01': {
          'USD': 1.0,
          'USDC': 2.0,
          'SDU': 3.0,
          'DU': 4.0,
          'U': 5.0,
          'DUS': 6.0,
        },
        '2024-04-02': {'USD': 7.0, 'USDC': 8.0, 'DUS': 9.0},
      };

      expect(
        CurrencyHistoryBinaryIO.readFromBytes(await writeAndRead(many)),
        many,
      );
    });
  });
}
