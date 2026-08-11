import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/presentation/widgets/navigation/navigation_tab_bar.dart';
import 'package:my_budget_client/presentation/screens/exchange_rates_screen.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab.dart';
import 'package:my_budget_client/presentation/widgets/inflation_tab.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';

class DataScreen extends StatefulWidget {
  final int initialTabIndex;
  const DataScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return ScreenShortcuts(
            actions: {
              'data_tab_1': () => tabController.index = 0,
              'data_tab_2': () => tabController.index = 1,
              'data_tab_3': () => tabController.index = 2,
              'add_action': () {
                // This is a placeholder; actual add is handled by child screens
              },
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Bottom placement is only safe when the shell moved its own
                  // navigation into a side rail. Deciding that by OS put this
                  // tab bar directly on top of the shell's bottom NavigationBar
                  // in a narrow desktop window, so measure the pane instead —
                  // the same test AdaptiveScaffold uses.
                  final isWide = constraints.maxWidth >= kMobileBreakpoint;
                  return Column(
                    children: [
                      if (!isWide) _buildTabBar(context),
                      const Expanded(
                        child: TabBarView(
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            ExchangeRatesScreen(isStandalone: false),
                            InflationTab(),
                            AssetTab(),
                          ],
                        ),
                      ),
                      if (isWide) _buildTabBar(context),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        return NavigationTabBar(
          items: [
            NavigationTabBarItem(
              icon: Icons.currency_exchange,
              label: context.l10n.hkActionDataTab1,
            ),
            NavigationTabBarItem(
              icon: Icons.trending_up,
              label: context.l10n.hkActionDataTab2,
            ),
            NavigationTabBarItem(
              icon: Icons.inventory_2,
              label: context.l10n.hkActionDataTab3,
            ),
          ],
          selectedIndex: tabController.index,
          onTap: (index) => tabController.index = index,
        );
      },
    );
  }
}
