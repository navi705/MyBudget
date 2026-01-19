import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_budget_client/presentation/widgets/navigation/navigation_tab_bar.dart';
import 'package:my_budget_client/presentation/screens/exchange_rates_screen.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab.dart';
import 'package:my_budget_client/presentation/widgets/inflation_tab.dart';

class DataScreen extends StatefulWidget {
  final int initialTabIndex;
  const DataScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              if (!isDesktop) _buildTabBar(context),
              const Expanded(
                child: TabBarView(
                  children: [
                    ExchangeRatesScreen(isStandalone: false),
                    InflationTab(),
                    AssetTab(),
                  ],
                ),
              ),
              if (isDesktop) _buildTabBar(context),
            ],
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
          items: const [
            NavigationTabBarItem(
              icon: Icons.currency_exchange,
              label: 'Exchange Rates',
            ),
            NavigationTabBarItem(icon: Icons.trending_up, label: 'Inflation'),
            NavigationTabBarItem(icon: Icons.inventory_2, label: 'Assets'),
          ],
          selectedIndex: tabController.index,
          onTap: (index) => tabController.animateTo(index),
        );
      },
    );
  }
}
