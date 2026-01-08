import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';

class AssetView extends StatelessWidget {
  final Function(AssetDataDomain) onEdit;

  const AssetView({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetBloc, AssetState>(
      builder: (context, state) {
        if (state.status == AssetStatus.loading && state.assetData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == AssetStatus.failure && state.assetData.isEmpty) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        if (state.assetData.isEmpty) {
          return const Center(child: Text('No assets found.'));
        }

        return Column(
          children: [
            Expanded(
              child: GroupedPaginatedList<AssetDataDomain, DateTime>(
                items: state.assetData,
                hasMoreDown: state.hasMore,
                onFetchMoreDown: () {
                  context.read<AssetBloc>().add(const LoadMoreAssetData());
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
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.assetType ?? 'Type'} • ${item.source} • ${DateFormat.yMMMMd().format(item.date)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.value.toStringAsFixed(2)} ${item.currency}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => onEdit(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => context.read<AssetBloc>().add(
                            DeleteAssetData(item.id!),
                          ),
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
