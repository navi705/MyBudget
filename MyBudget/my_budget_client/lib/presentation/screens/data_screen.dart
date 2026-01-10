import 'package:flutter/material.dart';
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
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const TabBar(
                  tabs: [
                    Tab(
                      text: 'Exchange Rates',
                      icon: Icon(Icons.currency_exchange, size: 28),
                    ),
                    Tab(
                      text: 'Inflation',
                      icon: Icon(Icons.trending_up, size: 28),
                    ),
                    Tab(
                      text: 'Assets',
                      icon: Icon(Icons.inventory_2, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ExchangeRatesScreen(isStandalone: false),
                InflationTab(),
                AssetTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
