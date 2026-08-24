import 'package:flutter/material.dart';
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/presentation/widgets/navigation/navigation_tab_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_currency_selector.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/day_balance_details.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/period_summary_widget.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_header.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/analytics_chart_selector.dart'; // Contains BalanceReportWidget
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Only from a cold state. The bloc outlives this screen (it is provided
    // app-wide) but the shell route remounts the screen on every tab switch,
    // and LoadDashboard restarts the whole pipeline: it tears down the
    // account/transaction/asset streams, refetches the rates for every date on
    // screen and redoes the walk-back. The bloc keeps its own caches fresh
    // through its subscriptions, so a remount has nothing to reload.
    final bloc = context.read<DashboardBloc>();
    if (bloc.state is DashboardInitial || bloc.state is DashboardLoadFailure) {
      bloc.add(LoadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardInitial || state is DashboardLoadInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DashboardLoadSuccess) {
          return ScreenShortcuts(
            actions: {
              'dashboard_tab_1': () =>
                  context.read<DashboardBloc>().add(const ChangeTab(0)),
              'dashboard_tab_2': () =>
                  context.read<DashboardBloc>().add(const ChangeTab(1)),
              'dashboard_tab_3': () =>
                  context.read<DashboardBloc>().add(const ChangeTab(2)),
              'prev_period': () => _navigatePeriod(context, state, -1),
              'next_period': () => _navigatePeriod(context, state, 1),

              // The dashboard header's own three controls. `pick_date` is
              // screen-agnostic, like the two above; the currency picker and
              // the month/year switch have no counterpart on any other screen,
              // so they keep ids of their own. All three are guarded on the
              // header being on screen at all - see [_runHeaderAction].
              'pick_date': () => _runHeaderAction(
                (state) => _showDashboardPeriodPicker(context, state),
              ),
              'dashboard_currency': () => _runHeaderAction(
                (state) => _showDashboardCurrencyPicker(context, state),
              ),
              'dashboard_switch_view': () => _runHeaderAction(
                (state) => _changeDashboardDateStep(
                  context,
                  _otherDashboardDateStep(state.dateStep),
                ),
              ),
            },
            child: Scaffold(
              // AppBar removed to maximize space
              body: SafeArea(
                // Calendar / Categories / Balance stays at the top at every
                // size. It used to move to the bottom above 600dp, so dragging
                // a desktop window 160px narrower teleported the primary tab
                // control from one edge of the screen to the other. Top is the
                // Material default, and it is the only position that cannot
                // collide with the shell's own bottom NavigationBar - which is
                // what the bottom placement was working around in the first
                // place (see data_screen.dart, which hit the same collision).
                child: Column(
                  children: [
                    _buildTabBar(context, state),
                    _buildUnconvertibleNotice(context, state),
                    Expanded(child: _buildBody(state)),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Center(child: Text(context.l10n.failedToLoadDashboard)),
        );
      },
    );
  }

  /// Compact, non-blocking warning shown above the dashboard body when some
  /// account/transaction currencies had no exchange-rate path to the selected
  /// currency. Those amounts are omitted from every total on this screen —
  /// which, unannounced, is how a whole account can vanish from net worth.
  /// Renders nothing when everything converted.
  Widget _buildUnconvertibleNotice(
    BuildContext context,
    DashboardLoadSuccess state,
  ) {
    if (state.unconvertibleCurrencies.isEmpty) return const SizedBox.shrink();

    final codes = state.unconvertibleCurrencies.toList()..sort();
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.dashboardUnconvertibleCurrencies(codes.join(', ')),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Runs one of the dashboard header's three controls on behalf of a hot key -
  /// or does nothing at all.
  ///
  /// The Hot Keys screen offers the three ids unconditionally and a bound key
  /// stays live for as long as this screen is, so the guard has to be exactly
  /// the buttons' own visibility condition. That is "the screen has loaded",
  /// nothing more: all three tabs draw a [DashboardHeader] - Categories and
  /// Balance build one directly, and the Calendar tab gets the same widget
  /// through [DashboardCalendar], with the same three callbacks. Excluding the
  /// Calendar tab left its header showing shortcut badges for keys that did
  /// nothing.
  ///
  /// The state is read from the bloc rather than closed over so the action runs
  /// against the tab that is showing when the key is pressed.
  void _runHeaderAction(void Function(DashboardLoadSuccess state) action) {
    final state = context.read<DashboardBloc>().state;
    if (state is! DashboardLoadSuccess) return;
    action(state);
  }

  void _navigatePeriod(
    BuildContext context,
    DashboardLoadSuccess state,
    int direction,
  ) {
    final current = state.selectedDay;
    DateTime newDate;
    // Default to month step if unknown, but usually dateStep is valid
    if (state.dateStep == DateStep.month) {
      newDate = DateTime(current.year, current.month + direction, 1);
    } else if (state.dateStep == DateStep.year) {
      newDate = DateTime(current.year + direction, current.month, 1);
    } else {
      // Day
      newDate = addDays(current, direction);
    }
    context.read<DashboardBloc>().add(SelectDay(newDate));
  }

  Widget _buildBody(DashboardLoadSuccess state) {
    switch (state.activeTabIndex) {
      case 0:
        return _buildCalendarView(state);
      case 1:
        return _buildCategoryView(state);
      case 2:
        return _buildBalanceView(state);
      default:
        // Fallback for any deprecated index
        return _buildCalendarView(state);
    }
  }

  Widget _buildCalendarView(DashboardLoadSuccess state) {
    final calendar = DashboardCalendar(
      selectedDay: state.selectedDay,
      dateStep: state.dateStep,
      dailyIncomes: state.dailyIncomes,
      dailyExpenses: state.dailyExpenses,
      dailyNetWorth: state.dailyNetWorth,
      currencyCode: state.selectedCurrency,
      availableCurrencies: state.availableCurrencies
          .map((e) => e.code)
          .toList(),
      onCurrencySelected: (code) {
        context.read<DashboardBloc>().add(ChangeCurrency(code));
      },
      onDateStepChanged: (step) {
        context.read<DashboardBloc>().add(ChangeDateStep(step));
      },
      onDaySelected: (day) {
        context.read<DashboardBloc>().add(SelectDay(day));
        // If in Year view, switch to Month view explicitly on selection
        if (state.dateStep == DateStep.year) {
          context.read<DashboardBloc>().add(
            const ChangeDateStep(DateStep.month),
          );
        }
      },
      onPrevious: () {
        final current = state.selectedDay;
        DateTime newDate;
        if (state.dateStep == DateStep.month) {
          newDate = DateTime(current.year, current.month - 1, 1); // Go to 1st
        } else {
          newDate = DateTime(current.year - 1, current.month, 1);
        }
        context.read<DashboardBloc>().add(SelectDay(newDate));
      },
      onNext: () {
        final current = state.selectedDay;
        DateTime newDate;
        if (state.dateStep == DateStep.month) {
          newDate = DateTime(current.year, current.month + 1, 1);
        } else {
          newDate = DateTime(current.year + 1, current.month, 1);
        }
        context.read<DashboardBloc>().add(SelectDay(newDate));
      },
      onTitleTap: () => _showDashboardPeriodPicker(context, state),
    );

    final summary = Column(
      children: [
        PeriodSummaryWidget(
          dateRangeStart: state.dateRangeStart,
          dateRangeEnd: state.dateRangeEnd,
          dailyIncomes: state.dailyIncomes,
          dailyExpenses: state.dailyExpenses,
          currencyCode: state.selectedCurrency,
          currencyDesignations: state.currencyDesignations, // Added
        ),
        const Divider(),
        DayBalanceDetails(
          accounts: state.accounts,
          dayBalances: state.dayBalances,
          date: state.selectedDay,
          currencyCode: state.selectedCurrency,
          styles: state.styles,
          currencyDesignations: state.currencyDesignations, // Added
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The grid caps itself at kDashboardCalendarColumnWidth for
        // readability, so on a maximised desktop window the single column left
        // the summary and the day's balances pushed below the fold with a wide
        // empty strip down either side. Above the breakpoint they move beside
        // the calendar instead, which is what the width was there for.
        if (constraints.maxWidth >= kDashboardTwoColumnBreakpoint) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: kDashboardPaneMaxWidth,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: kDashboardCalendarColumnWidth,
                      child: calendar,
                    ),
                    const SizedBox(width: 32),
                    Expanded(child: summary),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              calendar,
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kDashboardCalendarColumnWidth,
                  ),
                  child: summary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryView(DashboardLoadSuccess state) {
    return SingleChildScrollView(
      // One padding at every size: the tab bar sits above this pane whatever
      // the width, so there is no longer a wide layout that supplies its own
      // gap and a narrow one that does not.
      padding: const EdgeInsets.all(16.0),
      // The header and the period chips centre themselves in whatever width
      // they are handed, while the chart row below starts at the leading edge.
      // On a maximised desktop window that left the two visibly out of line
      // with a wide empty strip down the right; capping the pane keeps them
      // reading as one block.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kDashboardPaneMaxWidth),
          child: Column(
            children: [
              DashboardHeader(
                selectedDay: state.selectedDay,
                dateStep: state.dateStep,
                currencyCode: state.selectedCurrency,
                availableCurrencies: state.availableCurrencies
                    .map((e) => e.code)
                    .toList(),
                onPrevious: () => context.read<DashboardBloc>().add(
                  SelectDay(
                    state.dateStep == DateStep.month
                        ? DateTime(
                            state.selectedDay.year,
                            state.selectedDay.month - 1,
                            1,
                          )
                        : DateTime(state.selectedDay.year - 1, 1, 1),
                  ),
                ),
                onNext: () => context.read<DashboardBloc>().add(
                  SelectDay(
                    state.dateStep == DateStep.month
                        ? DateTime(
                            state.selectedDay.year,
                            state.selectedDay.month + 1,
                            1,
                          )
                        : DateTime(state.selectedDay.year + 1, 1, 1),
                  ),
                ),
                onTitleTap: () =>
                    _showDashboardPeriodPicker(context, state), // Fixed
                onCurrencySelected: (currency) =>
                    _selectDashboardCurrency(context, currency),
                onDateStepChanged: (step) =>
                    _changeDashboardDateStep(context, step),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(context.l10n.dashboardExpensesLabel),
                    selected: !state.isIncomeView,
                    onSelected: (val) => context.read<DashboardBloc>().add(
                      ToggleChartType(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: Text(context.l10n.dashboardIncomeLabel),
                    selected: state.isIncomeView,
                    onSelected: (val) => context.read<DashboardBloc>().add(
                      ToggleChartType(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CategoryPieChart(
                categoryConvertedTotals: state.categoryConvertedTotals,
                categories: state.categories,
                styles: state.styles,
                isIncome: state.isIncomeView,
                currencyCode: state.selectedCurrency, // Added
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceView(DashboardLoadSuccess state) {
    return Column(
      children: [
        // Date Navigation Header
        DashboardHeader(
          selectedDay: state.selectedDay,
          dateStep: state.dateStep,
          currencyCode: state.selectedCurrency,
          availableCurrencies: state.availableCurrencies
              .map((e) => e.code)
              .toList(),
          onPrevious: () => context.read<DashboardBloc>().add(
            SelectDay(
              state.dateStep == DateStep.month
                  ? DateTime(
                      state.selectedDay.year,
                      state.selectedDay.month - 1,
                      1,
                    )
                  : DateTime(state.selectedDay.year - 1, 1, 1),
            ),
          ),
          onNext: () => context.read<DashboardBloc>().add(
            SelectDay(
              state.dateStep == DateStep.month
                  ? DateTime(
                      state.selectedDay.year,
                      state.selectedDay.month + 1,
                      1,
                    )
                  : DateTime(state.selectedDay.year + 1, 1, 1),
            ),
          ),
          onTitleTap: () => _showDashboardPeriodPicker(context, state),
          onCurrencySelected: (currency) =>
              _selectDashboardCurrency(context, currency),
          onDateStepChanged: (step) => _changeDashboardDateStep(context, step),
        ),

        // Flexible Balance Report
        Expanded(
          child: BalanceReportWidget(
            dateRangeStart: state.dateRangeStart,
            dateRangeEnd: state.dateRangeEnd,
            dailyNetWorth: state.dailyNetWorth,
            dayBalances:
                state.dailyAccountBalances, // Pass historical account data
            currencyBreakdown: state.currencyBreakdown, // Added
            accountBreakdown: state.accountBreakdown, // Added
            accounts: state.accounts,
            currencyCode: state.selectedCurrency,
            currencyDesignations: state.currencyDesignations, // Added
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, DashboardLoadSuccess state) {
    return NavigationTabBar(
      selectedIndex: state.activeTabIndex,
      onTap: (index) => context.read<DashboardBloc>().add(ChangeTab(index)),
      items: [
        NavigationTabBarItem(
          icon: Icons.calendar_month,
          label: context.l10n.dashboardCalendarTab,
          tooltip: context.l10n.dashboardCalendarTooltip,
          hotkeyId: 'dashboard_tab_1',
          tooltipDescription: context.l10n.dashboardCalendarDescription,
        ),
        NavigationTabBarItem(
          icon: Icons.pie_chart,
          label: context.l10n.dashboardCategoriesTab,
          tooltip: context.l10n.dashboardCategoriesTooltip,
          hotkeyId: 'dashboard_tab_2',
          tooltipDescription: context.l10n.dashboardCategoriesDescription,
        ),
        NavigationTabBarItem(
          icon: Icons.show_chart,
          label: context.l10n.dashboardBalanceTab,
          tooltip: context.l10n.dashboardBalanceTooltip,
          hotkeyId: 'dashboard_tab_3',
          tooltipDescription: context.l10n.dashboardBalanceDescription,
        ),
      ],
    );
  }
}

// The date button, the currency picker and the month/year switch are drawn by
// DashboardHeader, several widgets below the ScreenShortcuts in
// _DashboardScreenState, and the Hot Keys screen offers all three as bindable
// actions. Top level functions let the button and the hotkey call one
// implementation instead of two that can drift apart.

void _showDashboardPeriodPicker(
  BuildContext context,
  DashboardLoadSuccess state,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (modalContext) => CalendarStepPicker(
      initialDate: state.selectedDay,
      initialStep: state.dateStep == DateStep.year
          ? DateStep.year
          : DateStep.month,
      initialFilterMode: FilterMode.date,
      rangeOptionVisibility: PickerVisibility.hidden,
      onApply: (date, range, step, mode) {
        final bloc = context.read<DashboardBloc>();
        bloc.add(SelectDay(date));
        // FIX: Also update DateStep if user selected different step in picker
        if (step != state.dateStep && step != DateStep.day) {
          bloc.add(ChangeDateStep(step));
        }
      },
    ),
  );
}

void _showDashboardCurrencyPicker(
  BuildContext context,
  DashboardLoadSuccess state,
) {
  showDashboardCurrencyPicker(
    context,
    selectedCurrency: state.selectedCurrency,
    availableCurrencies: state.availableCurrencies.map((e) => e.code).toList(),
    onSelected: (code) => _selectDashboardCurrency(context, code),
  );
}

/// Applies a currency chosen in the picker above.
void _selectDashboardCurrency(BuildContext context, String currencyCode) =>
    context.read<DashboardBloc>().add(ChangeCurrency(currencyCode));

/// Applies a choice made on the header's month/year switch.
void _changeDashboardDateStep(BuildContext context, DateStep step) =>
    context.read<DashboardBloc>().add(ChangeDateStep(step));

/// The step the switch's *other* segment stands for.
///
/// The switch has exactly two segments, so "toggle" and "tap the other one" are
/// the same gesture. Anything that is not a month lands on month, which is also
/// the segment the widget would draw as selected.
DateStep _otherDashboardDateStep(DateStep current) =>
    current == DateStep.month ? DateStep.year : DateStep.month;
