import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';

enum AssetStatus { initial, loading, success, failure }

class AssetState extends Equatable {
  final AssetStatus status;
  final List<AssetDataDomain> assetData;
  final bool hasMore;
  final int offset;
  final int limit;
  final bool isLoadingMore;
  final DateStep dateStep;
  final FilterMode filterMode;
  final DateTime activeDate;
  final DateTimeRange? activeDateRange;
  final Sort sort;
  final String? errorMessage;
  final int totalCount;

  const AssetState({
    this.status = AssetStatus.initial,
    this.assetData = const [],
    this.hasMore = true,
    this.offset = 0,
    this.limit = 50,
    this.isLoadingMore = false,
    this.dateStep = DateStep.month,
    this.filterMode = FilterMode.date,
    required this.activeDate,
    this.activeDateRange,
    this.sort = Sort.descending,
    this.errorMessage,
    this.totalCount = 0,
    this.selectedAssetId,
  });

  final String? selectedAssetId;

  AssetState copyWith({
    AssetStatus? status,
    List<AssetDataDomain>? assetData,
    bool? hasMore,
    int? offset,
    int? limit,
    bool? isLoadingMore,
    DateStep? dateStep,
    FilterMode? filterMode,
    DateTime? activeDate,
    DateTimeRange? activeDateRange,
    Sort? sort,
    String? errorMessage,
    int? totalCount,
    String? selectedAssetId,
  }) {
    return AssetState(
      status: status ?? this.status,
      assetData: assetData ?? this.assetData,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      dateStep: dateStep ?? this.dateStep,
      filterMode: filterMode ?? this.filterMode,
      activeDate: activeDate ?? this.activeDate,
      activeDateRange: activeDateRange ?? this.activeDateRange,
      sort: sort ?? this.sort,
      errorMessage: errorMessage ?? this.errorMessage,
      totalCount: totalCount ?? this.totalCount,
      selectedAssetId: selectedAssetId ?? this.selectedAssetId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    assetData,
    hasMore,
    offset,
    limit,
    isLoadingMore,
    dateStep,
    filterMode,
    activeDate,
    activeDateRange,
    sort,
    errorMessage,
    totalCount,
    selectedAssetId,
  ];
}
