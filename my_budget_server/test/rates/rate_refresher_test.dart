import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/rates/rate_provider.dart';
import 'package:my_budget_server/rates/rate_refresher.dart';
import 'package:my_budget_server/rates/rate_store.dart';
import 'package:test/test.dart';

class _MockRateStore extends Mock implements RateStore {}

/// A provider that answers from a map instead of the network.
class _FakeProvider implements RateProvider {
  _FakeProvider({
    this.published = const {},
    this.failOn = const {},
  });

  /// Days that have data. Anything else answers `null`, the way the upstream
  /// answers for a day it never published.
  final Map<DateTime, DayRates> published;

  /// Days the upstream refuses, as opposed to has nothing for.
  final Set<DateTime> failOn;

  @override
  final String baseCurrency = 'EUR';

  /// Every day asked for, in the order it was asked for.
  final List<DateTime> asked = [];

  @override
  Future<DayRates?> ratesFor(DateTime day) async {
    asked.add(day);
    if (failOn.contains(day)) throw RateProviderException('boom');
    return published[day];
  }
}

void main() {
  const today = '2026-03-14';
  DateTime day(int d) => DateTime.utc(2026, 3, d);
  DateTime clock() => DateTime.utc(2026, 3, 14, 11, 30);

  late _MockRateStore store;

  RateRefreshConfig config({
    DateTime? backfillFrom,
    int maxDaysPerRun = 400,
    int maxGapAttempts = 3,
    bool enabled = true,
  }) =>
      RateRefreshConfig(
        backfillFrom: backfillFrom ?? day(10),
        enabled: enabled,
        betweenRequests: Duration.zero,
        maxDaysPerRun: maxDaysPerRun,
        maxGapAttempts: maxGapAttempts,
      );

  RateRefresher refresherWith(_FakeProvider provider, RateRefreshConfig c) =>
      RateRefresher(
        store: store,
        provider: provider,
        config: c,
        clock: clock,
      );

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    store = _MockRateStore();
    when(store.ensureSchema).thenAnswer((_) async {});
    when(
      () => store.storedDays(
        baseCurrency: any(named: 'baseCurrency'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => <DateTime>{});
    when(
      () => store.exhaustedGapDays(
        since: any(named: 'since'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer((_) async => <DateTime>{});
    when(
      () => store.saveDay(
        day: any(named: 'day'),
        baseCurrency: any(named: 'baseCurrency'),
        rates: any(named: 'rates'),
        sourceId: any(named: 'sourceId'),
      ),
    ).thenAnswer((_) async => 2);
    when(
      () => store.recordGap(
        day: any(named: 'day'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async {});
    when(() => store.clearGap(any())).thenAnswer((_) async {});
  });

  test('fetches every missing day, newest first', () async {
    // Today's quote is what every screen reads; the history behind it is what
    // one screen reads when the user scrolls back. If a run is cut short, the
    // day everyone needs has to already be in.
    final provider = _FakeProvider(
      published: {for (var d = 10; d <= 14; d++) day(d): const {'USD': 1.09}},
    );
    final refresher = refresherWith(provider, config());

    final outcome = await refresher.refreshOnce();

    expect(provider.asked, [day(14), day(13), day(12), day(11), day(10)]);
    expect(outcome.daysFetched, 5);
    expect(outcome.rowsWritten, 10);
    expect(outcome.gaps, 0);
    expect(outcome.failures, 0);
  });

  test('skips days already stored, but always re-asks for today', () async {
    // Today's quote moves through the day; a stored copy from this morning is
    // not the same number as the one published this evening.
    when(
      () => store.storedDays(
        baseCurrency: any(named: 'baseCurrency'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => {day(14), day(13), day(12)});

    final provider = _FakeProvider(
      published: {for (var d = 10; d <= 14; d++) day(d): const {'USD': 1.09}},
    );

    await refresherWith(provider, config()).refreshOnce();

    expect(provider.asked, [day(14), day(11), day(10)]);
  });

  test('leaves a day alone once its gap attempts are spent', () async {
    when(
      () => store.exhaustedGapDays(
        since: any(named: 'since'),
        maxAttempts: any(named: 'maxAttempts'),
      ),
    ).thenAnswer((_) async => {day(12), day(11)});

    final provider = _FakeProvider(
      published: {for (var d = 10; d <= 14; d++) day(d): const {'USD': 1.09}},
    );

    await refresherWith(provider, config()).refreshOnce();

    expect(provider.asked, [day(14), day(13), day(10)]);
  });

  test('records a gap when the day published nothing', () async {
    final provider = _FakeProvider(
      published: {
        day(14): const {'USD': 1.09},
        day(12): const {'USD': 1.09},
      },
    );

    final outcome = await refresherWith(
      provider,
      config(backfillFrom: day(12)),
    ).refreshOnce();

    expect(outcome.daysFetched, 2);
    expect(outcome.gaps, 1);
    verify(() => store.recordGap(day: day(13), reason: any(named: 'reason')))
        .called(1);
    verifyNever(() => store.saveDay(
          day: day(13),
          baseCurrency: any(named: 'baseCurrency'),
          rates: any(named: 'rates'),
          sourceId: any(named: 'sourceId'),
        ));
  });

  test('a provider failure is not recorded as a gap', () async {
    // The day may well exist; a transport failure is worth retrying on the
    // next tick, which is minutes away and costs one request.
    final provider = _FakeProvider(
      published: {day(14): const {'USD': 1.09}},
      failOn: {day(13)},
    );

    final outcome = await refresherWith(
      provider,
      config(backfillFrom: day(13)),
    ).refreshOnce();

    expect(outcome.failures, 1);
    expect(outcome.gaps, 0);
    expect(outcome.daysFetched, 1);
    verifyNever(
      () => store.recordGap(day: any(named: 'day'), reason: any(named: 'reason')),
    );
  });

  test('a fetched day clears any gap recorded for it earlier', () async {
    final provider = _FakeProvider(published: {day(14): const {'USD': 1.09}});

    await refresherWith(provider, config(backfillFrom: day(14))).refreshOnce();

    verify(() => store.clearGap(day(14))).called(1);
  });

  test('stops at maxDaysPerRun so a first backfill always ends', () async {
    final provider = _FakeProvider(
      published: {for (var d = 1; d <= 14; d++) day(d): const {'USD': 1.09}},
    );

    final outcome = await refresherWith(
      provider,
      config(backfillFrom: day(1), maxDaysPerRun: 3),
    ).refreshOnce();

    expect(provider.asked, [day(14), day(13), day(12)]);
    expect(outcome.daysFetched, 3);
  });

  test('overlapping calls share one run instead of doubling the load',
      () async {
    final provider = _FakeProvider(
      published: {for (var d = 10; d <= 14; d++) day(d): const {'USD': 1.09}},
    );
    final refresher = refresherWith(provider, config());

    final first = refresher.refreshOnce();
    final second = refresher.refreshOnce();
    final outcomes = await Future.wait([first, second]);

    expect(provider.asked, hasLength(5));
    expect(outcomes.first, outcomes.last);
    verify(store.ensureSchema).called(1);
  });

  test('a later call runs again once the first has finished', () async {
    final provider = _FakeProvider(
      published: {day(14): const {'USD': 1.09}},
    );
    final refresher = refresherWith(provider, config(backfillFrom: day(14)));

    await refresher.refreshOnce();
    await refresher.refreshOnce();

    expect(provider.asked, [day(14), day(14)]);
  });

  test('disabled means the loop never arms', () {
    final provider = _FakeProvider();
    final refresher = refresherWith(provider, config(enabled: false));

    refresher.start();

    expect(refresher.isRunning, isFalse);
    expect(provider.asked, isEmpty);
  });

  group('RateRefreshConfig.fromEnvironment', () {
    test('falls back to values that are safe on a personal server', () {
      final c = RateRefreshConfig.fromEnvironment(const {});

      expect(c.enabled, isTrue);
      expect(c.baseCurrency, 'EUR');
      expect(c.backfillFrom, DateTime.utc(2024, 4));
      expect(c.interval, const Duration(hours: 6));
      expect(c.maxGapAttempts, 3);
    });

    test('reads the operator settings', () {
      final c = RateRefreshConfig.fromEnvironment(const {
        'RATES_ENABLED': 'no',
        'RATES_BASE': 'usd',
        'RATES_BACKFILL_FROM': today,
        'RATES_REFRESH_MINUTES': '30',
        'RATES_REQUEST_DELAY_MS': '50',
        'RATES_MAX_DAYS_PER_RUN': '7',
        'RATES_MAX_GAP_ATTEMPTS': '1',
      });

      expect(c.enabled, isFalse);
      expect(c.baseCurrency, 'USD');
      expect(c.backfillFrom, DateTime.utc(2026, 3, 14));
      expect(c.interval, const Duration(minutes: 30));
      expect(c.betweenRequests, const Duration(milliseconds: 50));
      expect(c.maxDaysPerRun, 7);
      expect(c.maxGapAttempts, 1);
    });

    test('an unparseable number falls back rather than crashing startup', () {
      final c = RateRefreshConfig.fromEnvironment(const {
        'RATES_REFRESH_MINUTES': 'hourly',
        'RATES_BACKFILL_FROM': 'the beginning',
      });

      expect(c.interval, const Duration(hours: 6));
      expect(c.backfillFrom, DateTime.utc(2024, 4));
    });
  });
}
