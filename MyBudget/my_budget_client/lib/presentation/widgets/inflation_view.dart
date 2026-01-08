import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';

class InflationView extends StatelessWidget {
  final Function(InflationRateDomain) onEdit;

  const InflationView({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      builder: (context, state) {
        if (state.status == InflationStatus.loading && state.rates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == InflationStatus.failure && state.rates.isEmpty) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        if (state.rates.isEmpty) {
          return const Center(child: Text('No inflation rates found.'));
        }

        return Column(
          children: [
            Expanded(
              child: GroupedPaginatedList<InflationRateDomain, DateTime>(
                items: state.rates,
                hasMoreDown: state.hasMore,
                onFetchMoreDown: () {
                  context.read<InflationBloc>().add(LoadMoreInflationRates());
                },
                groupKeyGetter: (item) =>
                    DateTime(item.date.year, item.date.month),
                keyComparator: (a, b) {
                  if (state.sort.toString().contains('ascending')) {
                    return a.compareTo(b);
                  }
                  return b.compareTo(a);
                },
                groupHeaderBuilder: (context, date) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Text(
                      DateFormat.yMMMM().format(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                itemBuilder: (context, item) {
                  return ListTile(
                    title: Text(
                      '${item.country ?? 'Global'} (Preset: ${item.preset})',
                    ),
                    subtitle: Text(DateFormat.yMMMMd().format(item.date)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.percent.toStringAsFixed(2)}%',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: item.percent >= 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => onEdit(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            context.read<InflationBloc>().add(
                              DeleteInflationRate(
                                date: item.date,
                                country: item.country,
                                preset: item.preset,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (state.isLoadingMore) const LinearProgressIndicator(),
          ],
        );
      },
    );
  }
}
