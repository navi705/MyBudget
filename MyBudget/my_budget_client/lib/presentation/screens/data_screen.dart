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
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(
                      text: 'Exchange Rates',
                      icon: Icon(Icons.currency_exchange),
                    ),
                    Tab(text: 'Inflation', icon: Icon(Icons.trending_up)),
                    Tab(text: 'Assets', icon: Icon(Icons.inventory_2)),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const ExchangeRatesScreen(isStandalone: false),
            const InflationTab(),
            const AssetTab(),
          ],
        ),
      ),
    );
  }
}
