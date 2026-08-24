// [ImportDataUtils.parseOneMoneyCsv] is the third-party import path: it reads a
// OneMoney export, which is a spreadsheet file written by another program and
// therefore uses CRLF. It is pure (no database, no network), so it is driven
// here straight off bytes.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';

ImportFileData fileOf(String content) => ImportFileData(
  name: 'onemoney.csv',
  bytes: Uint8List.fromList(utf8.encode(content)),
);

const _ruHeader =
    'ДАТА,ТИП,СО СЧЁТА,НА СЧЁТ / НА КАТЕГОРИЮ,СУММА,ВАЛЮТА,'
    'СУММА 2,ВАЛЮТА 2,МЕТКИ,ЗАМЕТКИ';
const _enHeader =
    'DATE,TYPE,FROM ACCOUNT,TO ACCOUNT/TO CATEGORY,AMOUNT,'
    'CURRENCY,AMOUNT 2,CURRENCY 2,TAGS,NOTES';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The OneMoney date column is parsed with a locale-pinned DateFormat so the
  // parse does not depend on which language the device reads in. Load its
  // CLDR data before the parser runs.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('line endings', () {
    test('a CRLF file - what every spreadsheet writes - is accepted', () async {
      // The parser was pinned to `eol: '\n'`, which does not mean "accept LF",
      // it means "\r is ordinary text". The last header cell then read
      // "ЗАМЕТКИ\r" and the whole file was rejected as "headers do not match".
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,Хлеб\r\n',
        ),
      );

      expect(parsed.records, hasLength(1));
      final record = parsed.records.single;
      expect(record.date, DateTime(2025, 3, 15));
      expect(record.type, 'Expense');
      expect(record.from, 'Кошелёк');
      expect(record.to, 'Продукты');
      expect(record.amount, -12.5);
      expect(record.currency, 'EUR');
      expect(record.notes, 'Хлеб');
    });

    test(
      'the last column of a CRLF row carries no trailing carriage return',
      () async {
        final parsed = await ImportDataUtils.parseOneMoneyCsv(
          fileOf(
            '$_ruHeader\r\n'
            '15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,Заметка\r\n',
          ),
        );
        expect(parsed.records.single.notes, 'Заметка');
        expect(parsed.records.single.notes.contains('\r'), isFalse);
      },
    );

    test('an LF-only file is still accepted', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\n'
          '15.03.2025,Доход,Работа,Кошелёк,1000,EUR,,,,Зарплата\n',
        ),
      );
      expect(parsed.records.single.type, 'Income');
      expect(parsed.records.single.amount, 1000);
    });
  });

  group('headers', () {
    test('the English header is recognised, with its MM/dd/yy dates', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_enHeader\r\n'
          '03/15/25,Expense,Wallet,Groceries,-12.5,EUR,,,,Bread\r\n',
        ),
      );
      expect(parsed.records.single.date, DateTime(2025, 3, 15));
      expect(parsed.records.single.type, 'Expense');
    });

    test('a UTF-8 BOM in front of the first header is stripped', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '\uFEFF$_ruHeader\r\n'
          '15.03.2025,Перевод,Кошелёк,Копилка,50,EUR,50,EUR,,\r\n',
        ),
      );
      expect(parsed.records.single.type, 'Transfer');
      expect(parsed.records.single.amount2, 50);
      expect(parsed.records.single.currency2, 'EUR');
    });

    test('padding around a header cell does not disqualify the file', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '${_ruHeader.replaceFirst('ЗАМЕТКИ', 'ЗАМЕТКИ ')}\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,-1,EUR,,,,x\r\n',
        ),
      );
      expect(parsed.records, hasLength(1));
    });

    test('a file that is not a OneMoney export is refused by name', () async {
      expect(
        () => ImportDataUtils.parseOneMoneyCsv(
          fileOf('Date,Amount,Account\r\n2025-03-15,1.5,Cash\r\n'),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('CSV headers do not match'),
          ),
        ),
      );
    });

    test('an empty file is refused', () async {
      expect(
        () => ImportDataUtils.parseOneMoneyCsv(fileOf('')),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('empty'),
          ),
        ),
      );
    });
  });

  group('values', () {
    test('a comma and a quote inside a quoted field survive', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\r\n'
          '15.03.2025,Расход,"Банк, ООО",Продукты,-12.5,EUR,,,,'
          '"Купил ""хлеб"", молоко"\r\n',
        ),
      );
      expect(parsed.records.single.from, 'Банк, ООО');
      expect(parsed.records.single.notes, 'Купил "хлеб", молоко');
    });

    test('a comma decimal separator is read as a decimal point', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,"-12,53",EUR,,,,x\r\n',
        ),
      );
      expect(parsed.records.single.amount, -12.53);
    });

    test(
      'a row that cannot be parsed is skipped, leaving the rest intact',
      () async {
        final parsed = await ImportDataUtils.parseOneMoneyCsv(
          fileOf(
            '$_ruHeader\r\n'
            '15.03.2025,Расход,Кошелёк,Продукты,-1,EUR,,,,first\r\n'
            '15.03.2025,Расход,Кошелёк,Продукты,not-a-number,EUR,,,,bad\r\n'
            '16.03.2025,Расход,Кошелёк,Продукты,-2,EUR,,,,second\r\n',
          ),
        );
        expect(parsed.records.map((r) => r.notes), ['first', 'second']);
      },
    );

    // `double.parse` reads all three of these as numbers, so they came
    // through the amount column untouched and every total that ever summed
    // the row was NaN afterwards - a balance no edit to any other transaction
    // can repair. They are now as unreadable as a letter in the column, and
    // skip exactly the one row, the same way.
    for (final spelling in const ['NaN', 'Infinity', '-Infinity']) {
      test('"$spelling" in the amount column skips only its own row', () async {
        final parsed = await ImportDataUtils.parseOneMoneyCsv(
          fileOf(
            '$_ruHeader\r\n'
            '15.03.2025,Расход,Кошелёк,Продукты,$spelling,EUR,,,,bad\r\n'
            '16.03.2025,Расход,Кошелёк,Продукты,-2,EUR,,,,good\r\n',
          ),
        );
        expect(parsed.records.map((r) => r.notes), ['good']);
      });

      test('"$spelling" in the second amount skips its row too', () async {
        final parsed = await ImportDataUtils.parseOneMoneyCsv(
          fileOf(
            '$_ruHeader\r\n'
            '15.03.2025,Перевод,Кошелёк,Банк,-2,EUR,$spelling,USD,,bad\r\n'
            '16.03.2025,Расход,Кошелёк,Продукты,-2,EUR,,,,good\r\n',
          ),
        );
        expect(parsed.records.map((r) => r.notes), ['good']);
      });
    }

    test('every finite amount around a non-finite one still arrives', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,-1,EUR,,,,first\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,NaN,EUR,,,,bad\r\n'
          '16.03.2025,Расход,Кошелёк,Продукты,"-2,5",EUR,,,,second\r\n',
        ),
      );
      expect(parsed.records.map((r) => r.notes), ['first', 'second']);
      expect(parsed.records.last.amount, -2.5);
    });
  });

  group('the trailing account-balance section', () {
    test(
      'is read after the blank separator line, header row and all',
      () async {
        final parsed = await ImportDataUtils.parseOneMoneyCsv(
          fileOf(
            '$_ruHeader\r\n'
            '15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,x\r\n'
            '\r\n'
            'НАЗВАНИЕ,БАЛАНС,ВАЛЮТА\r\n'
            'Кошелёк,1234.56,EUR\r\n'
            '"Банк, ООО",0,JPY\r\n',
          ),
        );

        expect(parsed.records, hasLength(1));
        expect(parsed.accountBalances, hasLength(2));
        expect(parsed.accountBalances.first.name, 'Кошелёк');
        expect(parsed.accountBalances.first.balance, 1234.56);
        expect(parsed.accountBalances.first.currency, 'EUR');
        expect(parsed.accountBalances.last.name, 'Банк, ООО');
        expect(
          parsed.accountBalances.last.currency,
          'JPY',
          reason:
              'the currency is the last cell of a CRLF row, so a stray '
              'carriage return would land exactly here',
        );
      },
    );

    test('a balance written with a decimal comma is read, not skipped', () async {
      // The amount column of the same file is parsed through a
      // `replaceAll(',', '.')` because a Russian export writes "1234,56"; the
      // balance column was not, and its row was dropped by the catch that
      // skips unparseable balances. The result was an import that carried
      // every transaction and silently no opening balances at all.
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,"-12,5",EUR,,,,x\r\n'
          '\r\n'
          'НАЗВАНИЕ,БАЛАНС,ВАЛЮТА\r\n'
          'Кошелёк,"1234,56",EUR\r\n',
        ),
      );

      expect(parsed.records.single.amount, -12.5);
      expect(parsed.accountBalances, hasLength(1));
      expect(parsed.accountBalances.single.balance, 1234.56);
    });

    test('a balance cell that is not a number still skips only its own row', () async {
      // The catch is what keeps one bad row from ending the import, and the
      // comma fix must not turn a junk cell into a crash.
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_ruHeader\r\n'
          '15.03.2025,Расход,Кошелёк,Продукты,-12.5,EUR,,,,x\r\n'
          '\r\n'
          'НАЗВАНИЕ,БАЛАНС,ВАЛЮТА\r\n'
          'Сломанный,не число,EUR\r\n'
          'Кошелёк,10.5,EUR\r\n',
        ),
      );

      expect(parsed.accountBalances, hasLength(1));
      expect(parsed.accountBalances.single.name, 'Кошелёк');
    });

    test('the English balance header is recognised too', () async {
      final parsed = await ImportDataUtils.parseOneMoneyCsv(
        fileOf(
          '$_enHeader\r\n'
          '03/15/25,Expense,Wallet,Groceries,-12.5,EUR,,,,x\r\n'
          '\r\n'
          'Name,Balance,Currency\r\n'
          'Wallet,10.5,EUR\r\n',
        ),
      );
      expect(parsed.accountBalances, hasLength(1));
      expect(parsed.accountBalances.single.name, 'Wallet');
    });
  });
}
