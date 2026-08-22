import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Locale-aware date rendering.
///
/// The app ships ten locales, two of them RTL, so every user-facing date has
/// to come from `intl`'s locale data rather than from a pattern typed into a
/// widget. Hardcoded `DateFormat('dd.MM.yyyy')` and raw `DateTime.toString()`
/// print European or machine formats to an Arabic, Hindi or Chinese reader.
///
/// Call [ensureInitialized] once at startup (it is idempotent) so the symbol
/// data for the active locale is loaded before the first frame.
class DateDisplay {
  const DateDisplay._();

  static bool _initialized = false;

  /// Load `intl`'s locale data. Safe to call more than once.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await initializeDateFormatting();
    _initialized = true;
  }

  /// The BCP-47 name `intl` should format with, taken from the widget tree.
  /// `DateFormat` verifies it and falls back to the default locale when the
  /// symbol data for it was never loaded, so this never throws on an exotic
  /// locale.
  static String localeOf(BuildContext context) =>
      Localizations.localeOf(context).toString();

  /// Numeric date for dense surfaces: fields, filter chips, table cells.
  /// `21.08.2026` in ru, `8/21/2026` in en_US, `٢١‏/٨‏/٢٠٢٦` in ar.
  static String short(BuildContext context, DateTime date) =>
      DateFormat.yMd(localeOf(context)).format(date);

  /// Day and month with no year, for axis ticks and other dense labels where
  /// the year is already established by the surrounding range.
  /// `08/22` in en_US, `22.08` in ru.
  static String dayMonth(BuildContext context, DateTime date) =>
      DateFormat.Md(localeOf(context)).format(date);

  /// Date with the month spelled out, for single-date fields where there is
  /// room for it. `22 Aug 2026` in en_GB, `22 авг. 2026 г.` in ru.
  static String medium(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(localeOf(context)).format(date);

  /// Date with a spelled-out weekday, for list section headers.
  static String listHeader(BuildContext context, DateTime date) =>
      DateFormat.yMMMEd(localeOf(context)).format(date);

  /// Month and year, for period pickers and calendar headers.
  static String monthYear(BuildContext context, DateTime date) =>
      DateFormat.yMMMM(localeOf(context)).format(date);

  /// Date and time, for sync timestamps and audit rows.
  static String dateTime(BuildContext context, DateTime date) {
    final locale = localeOf(context);
    return '${DateFormat.yMd(locale).format(date)} '
        '${DateFormat.Hm(locale).format(date)}';
  }

  /// The locale's first day of the week as a `DateTime.monday`-style constant
  /// (1 = Monday … 7 = Sunday).
  ///
  /// `intl` reports it 0-based with 0 = Monday, so Saturday (Arabic) is 5 and
  /// Sunday (en_US) is 6. Deriving the calendar's first column from this is
  /// what stops the grid being a day off for three of the shipped locales.
  static int firstDayOfWeek(BuildContext context) {
    final symbols = DateFormat.yMd(localeOf(context)).dateSymbols;
    return symbols.FIRSTDAYOFWEEK + 1;
  }

  /// Weekday labels ordered for the locale, starting at [firstDayOfWeek].
  /// [narrow] picks the one-letter names instead of the short ones.
  static List<String> weekdayLabels(
    BuildContext context, {
    bool narrow = false,
  }) {
    final locale = localeOf(context);
    // 'EEEEE' is the narrow name ("M"), 'E' the short one ("Mon").
    final format = DateFormat(narrow ? 'EEEEE' : 'E', locale);
    final first = firstDayOfWeek(context);
    // 2024-01-01 was a Monday, so adding (weekday - 1) lands on any weekday.
    final monday = DateTime(2024, 1, 1);
    return List<String>.generate(7, (i) {
      final weekday = (first - 1 + i) % 7;
      return format.format(monday.add(Duration(days: weekday)));
    });
  }
}
