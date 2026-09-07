import 'dart:async';
import 'dart:io';

import 'package:my_budget_server/rates/rate_provider.dart';
import 'package:my_budget_server/rates/rate_store.dart';

/// How the refresher is allowed to behave, all of it operator-tunable.
///
/// Read from the environment once, at construction, rather than per run: an
/// operator changing a variable expects to restart the server, and a value
/// re-read mid-run could change the meaning of a loop already executing.
class RateRefreshConfig {
  /// Built by [RateRefreshConfig.fromEnvironment] in production; the
  /// constructor is what a test pins values with.
  const RateRefreshConfig({
    required this.backfillFrom,
    this.enabled = true,
    this.baseCurrency = 'EUR',
    this.interval = const Duration(hours: 6),
    this.betweenRequests = const Duration(milliseconds: 200),
    this.maxDaysPerRun = 400,
    this.maxGapAttempts = 3,
  });

  /// Reads the operator's settings, falling back to values that are safe on a
  /// personal server: on, quoted in EUR, and reaching back to the first day the
  /// app itself ever had data for.
  factory RateRefreshConfig.fromEnvironment([Map<String, String>? env]) {
    final source = env ?? Platform.environment;

    bool flag(String key, {required bool fallback}) {
      final raw = source[key]?.trim().toLowerCase();
      if (raw == null || raw.isEmpty) return fallback;
      return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
    }

    int number(String key, int fallback) =>
        int.tryParse(source[key]?.trim() ?? '') ?? fallback;

    // 2024-04-01 is where the app's own bundled history started, so a server
    // that reaches back this far can answer for every date a device already
    // has an opinion about.
    final backfill =
        DateTime.tryParse(source['RATES_BACKFILL_FROM']?.trim() ?? '') ??
            DateTime.utc(2024, 4);

    return RateRefreshConfig(
      enabled: flag('RATES_ENABLED', fallback: true),
      baseCurrency: (source['RATES_BASE']?.trim().isNotEmpty ?? false)
          ? source['RATES_BASE']!.trim().toUpperCase()
          : 'EUR',
      backfillFrom: normalizeDay(backfill),
      interval: Duration(minutes: number('RATES_REFRESH_MINUTES', 360)),
      betweenRequests:
          Duration(milliseconds: number('RATES_REQUEST_DELAY_MS', 200)),
      maxDaysPerRun: number('RATES_MAX_DAYS_PER_RUN', 400),
      maxGapAttempts: number('RATES_MAX_GAP_ATTEMPTS', 3),
    );
  }

  /// Whether the loop runs at all. Off still serves whatever is stored.
  final bool enabled;

  /// The currency every fetched quote is expressed against.
  final String baseCurrency;

  /// Oldest day the backfill reaches for.
  final DateTime backfillFrom;

  /// Gap between two runs of the loop.
  final Duration interval;

  /// Pause between two upstream requests.
  ///
  /// The provider publishes no rate limit, which is a reason to be careful with
  /// it rather than a licence: a first backfill is ~900 requests, and firing
  /// those as fast as the socket allows is how a free CDN starts refusing a
  /// server it was previously happy to serve.
  final Duration betweenRequests;

  /// Upper bound on days fetched in one run, so a first backfill cannot run
  /// unbounded and so a run always ends.
  final int maxDaysPerRun;

  /// How many times a day with no published data is asked for again before it
  /// is left alone.
  final int maxGapAttempts;
}

/// What one refresh run did. Returned rather than only logged so a test — and
/// later an operator endpoint — can see it.
typedef RefreshOutcome = ({
  int daysFetched,
  int rowsWritten,
  int gaps,
  int failures,
});

/// Keeps the server's copy of the published rates current.
///
/// Two jobs in one loop, because they are the same job at different distances:
/// today's quote, which the app needs to price anything at all, and the
/// history behind it, which it needs to price last March. Both are "days this
/// server does not have yet".
class RateRefresher {
  /// [clock] exists so a test can pin "today" without waiting for one.
  RateRefresher({
    required RateStore store,
    required RateProvider provider,
    required RateRefreshConfig config,
    DateTime Function()? clock,
  })  : _store = store,
        _provider = provider,
        _config = config,
        _now = clock ?? DateTime.now;

  final RateStore _store;
  final RateProvider _provider;
  final RateRefreshConfig _config;
  final DateTime Function() _now;

  Timer? _timer;
  Future<RefreshOutcome>? _running;

  /// Whether the periodic loop is armed. A run may still be in flight after
  /// [stop], which cancels the timer and lets the current pass finish.
  bool get isRunning => _timer != null;

  /// Starts the loop: one run now, then one every [RateRefreshConfig.interval].
  ///
  /// The first run is not awaited by the caller — it is a ~900-request backfill
  /// on an empty database, and holding the first HTTP request the server ever
  /// receives behind it would make a cold start look like a hang.
  void start() {
    if (!_config.enabled) {
      print('[RATES] disabled (RATES_ENABLED); serving whatever is stored');
      return;
    }
    if (_timer != null) return;

    unawaited(_runGuarded());
    _timer = Timer.periodic(_config.interval, (_) => unawaited(_runGuarded()));
    print('[RATES] refresher started: base ${_config.baseCurrency}, '
        'every ${_config.interval.inMinutes} min, '
        'history from ${_config.backfillFrom.toIso8601String()}');
  }

  /// Cancels the periodic loop. A run already in flight is left to finish.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _runGuarded() async {
    try {
      final outcome = await refreshOnce();
      if (outcome.daysFetched > 0 || outcome.failures > 0) {
        print('[RATES] run: ${outcome.daysFetched} day(s), '
            '${outcome.rowsWritten} row(s), ${outcome.gaps} gap(s), '
            '${outcome.failures} failure(s)');
      }
    } on Object catch (e, stackTrace) {
      // A refresh failing must never take the server with it: the rates it
      // already holds keep being served, and the next tick tries again.
      print('[RATES] run failed: $e\n$stackTrace');
    }
  }

  /// Fetches every day this server is missing, oldest gaps last.
  ///
  /// Concurrent calls share one run rather than queueing a second: the periodic
  /// timer and a manual trigger both land here, and two overlapping backfills
  /// would double the request rate against the provider for no extra coverage.
  Future<RefreshOutcome> refreshOnce() {
    final inFlight = _running;
    if (inFlight != null) return inFlight;

    final future = _refresh();
    _running = future;
    return future.whenComplete(() => _running = null);
  }

  Future<RefreshOutcome> _refresh() async {
    await _store.ensureSchema();

    final today = normalizeDay(_now().toUtc());
    final stored = await _store.storedDays(
      baseCurrency: _config.baseCurrency,
      since: _config.backfillFrom,
    );
    final exhausted = await _store.exhaustedGapDays(
      since: _config.backfillFrom,
      maxAttempts: _config.maxGapAttempts,
    );

    // Newest first. Today's quote is what every screen reads; the history
    // behind it is what one screen reads when the user scrolls back, so if a
    // run is cut short by [maxDaysPerRun] the day everyone needs is already in.
    final wanted = <DateTime>[];
    for (var day = today;
        !day.isBefore(_config.backfillFrom);
        day = day.subtract(const Duration(days: 1))) {
      if (stored.contains(day) && !day.isAtSameMomentAs(today)) continue;
      if (exhausted.contains(day)) continue;
      wanted.add(day);
      if (wanted.length >= _config.maxDaysPerRun) break;
    }

    var daysFetched = 0;
    var rowsWritten = 0;
    var gaps = 0;
    var failures = 0;

    for (var i = 0; i < wanted.length; i++) {
      if (i > 0 && _config.betweenRequests > Duration.zero) {
        await Future<void>.delayed(_config.betweenRequests);
      }

      final day = wanted[i];
      try {
        final rates = await _provider.ratesFor(day);
        if (rates == null || rates.isEmpty) {
          // Published nothing for that day. Recorded so the next run does not
          // ask again forever — a permanent hole in the upstream data set
          // would otherwise consume the whole per-run budget on every run and
          // starve the days that do exist.
          gaps++;
          await _store.recordGap(day: day, reason: 'no data published');
          continue;
        }

        rowsWritten += await _store.saveDay(
          day: day,
          baseCurrency: _provider.baseCurrency,
          rates: rates,
          sourceId: _sourceId,
        );
        daysFetched++;
        await _store.clearGap(day);
      } on RateProviderException catch (e) {
        // The upstream refused or broke. Not recorded as a gap: the day may
        // well exist and a transport failure is worth retrying on the next
        // tick, which is minutes away and costs one request.
        failures++;
        print('[RATES] ${day.toIso8601String()}: $e');
      }
    }

    return (
      daysFetched: daysFetched,
      rowsWritten: rowsWritten,
      gaps: gaps,
      failures: failures,
    );
  }

  /// Stamped into `source_id` so a stored row says where it came from, and so
  /// a later provider swap is visible in the data rather than only in a log.
  String get _sourceId => 'server:${_provider.runtimeType}';
}
