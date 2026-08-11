import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/presentation/widgets/navigation/navigation_tab_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';
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
    context.read<DashboardBloc>().add(LoadDashboard());
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
            },
            child: Scaffold(
              // AppBar removed to maximize space
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The tab bar sits at the bottom only when the shell put its
                    // own navigation in a side rail. Keying that off the OS meant
                    // a narrow desktop window — where the shell falls back to a
                    // bottom NavigationBar — stacked two bottom bars on top of
                    // each other. Same breakpoint, measured on this pane's own
                    // box, keeps the two decisions in agreement.
                    final isWide = constraints.maxWidth >= kMobileBreakpoint;
                    return Column(
                      children: [
                        if (isWide) const SizedBox(height: 10),
                        if (!isWide) _buildTabBar(context, state),
                        Expanded(child: _buildBody(state, isWide: isWide)),
                        if (isWide) _buildTabBar(context, state),
                      ],
                    );
                  },
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
      newDate = current.add(Duration(days: direction));
    }
    context.read<DashboardBloc>().add(SelectDay(newDate));
  }

  Widget _buildBody(DashboardLoadSuccess state, {required bool isWide}) {
    switch (state.activeTabIndex) {
      case 0:
        return _buildCalendarView(state);
      case 1:
        return _buildCategoryView(state, isWide: isWide);
      case 2:
        return _buildBalanceView(state);
      default:
        // Fallback for any deprecated index
        return _buildCalendarView(state);
    }
  }

  Widget _buildCalendarView(DashboardLoadSuccess state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // View Selector & Currency
          // Calendar with integrated header
          DashboardCalendar(
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
                newDate = DateTime(
                  current.year,
                  current.month - 1,
                  1,
                ); // Go to 1st
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
            onTitleTap: () => _showPeriodPicker(context, state),
          ),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryView(
    DashboardLoadSuccess state, {
    required bool isWide,
  }) {
    return SingleChildScrollView(
      // Wide layouts already get a 10dp gap above this pane from the tab bar
      // being moved to the bottom, so only narrow ones need their own top pad.
      padding: EdgeInsets.fromLTRB(16.0, isWide ? 0.0 : 16.0, 16.0, 16.0),
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
            onTitleTap: () => _showPeriodPicker(context, state), // Fixed
            onCurrencySelected: (currency) =>
                context.read<DashboardBloc>().add(ChangeCurrency(currency)),
            onDateStepChanged: (step) =>
                context.read<DashboardBloc>().add(ChangeDateStep(step)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(context.l10n.dashboardExpensesLabel),
                selected: !state.isIncomeView,
                onSelected: (val) =>
                    context.read<DashboardBloc>().add(ToggleChartType(false)),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: Text(context.l10n.dashboardIncomeLabel),
                selected: state.isIncomeView,
                onSelected: (val) =>
                    context.read<DashboardBloc>().add(ToggleChartType(true)),
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
          onTitleTap: () => _showPeriodPicker(context, state),
          onCurrencySelected: (currency) =>
              context.read<DashboardBloc>().add(ChangeCurrency(currency)),
          onDateStepChanged: (step) =>
              context.read<DashboardBloc>().add(ChangeDateStep(step)),
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

  void _showPeriodPicker(BuildContext context, DashboardLoadSuccess state) {
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
}
