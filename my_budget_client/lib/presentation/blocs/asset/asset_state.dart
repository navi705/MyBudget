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
    this.nameFilter,
    this.assetTypeFilters,
    this.descriptionFilter,
    this.currencyCodeFilters,
    this.sourceFilters,
    this.presetFilters,
    this.minValueFilter,
    this.maxValueFilter,
    this.selectedAssets = const {},
    this.isSelectionModeActive = false,
  });

  final String? selectedAssetId;
  final String? nameFilter;
  final List<String>? assetTypeFilters;
  final String? descriptionFilter;
  final List<String>? currencyCodeFilters;
  final List<String>? sourceFilters;
  final List<int>? presetFilters;
  final double? minValueFilter;
  final double? maxValueFilter;
  final Set<AssetDataDomain> selectedAssets;
  final bool isSelectionModeActive;

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
    String? nameFilter,
    List<String>? assetTypeFilters,
    String? descriptionFilter,
    List<String>? currencyCodeFilters,
    List<String>? sourceFilters,
    List<int>? presetFilters,
    double? minValueFilter,
    double? maxValueFilter,
    Set<AssetDataDomain>? selectedAssets,
    bool? isSelectionModeActive,
    bool forceNullName = false,
    bool forceNullAssetTypes = false,
    bool forceNullDescription = false,
    bool forceNullCurrencyCodes = false,
    bool forceNullSources = false,
    bool forceNullPresets = false,
    bool forceNullMinValue = false,
    bool forceNullMaxValue = false,
    bool forceNullSelectedAssetId = false,
    bool forceNullErrorMessage = false,
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
      // Without a way to clear it the message outlived the failure that set
      // it, so a second identical failure could not be told apart from the
      // stale one still in the state.
      errorMessage: forceNullErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      totalCount: totalCount ?? this.totalCount,
      selectedAssetId: forceNullSelectedAssetId
          ? null
          : (selectedAssetId ?? this.selectedAssetId),
      nameFilter: forceNullName ? null : (nameFilter ?? this.nameFilter),
      assetTypeFilters: forceNullAssetTypes
          ? null
          : (assetTypeFilters ?? this.assetTypeFilters),
      descriptionFilter: forceNullDescription
          ? null
          : (descriptionFilter ?? this.descriptionFilter),
      currencyCodeFilters: forceNullCurrencyCodes
          ? null
          : (currencyCodeFilters ?? this.currencyCodeFilters),
      sourceFilters: forceNullSources
          ? null
          : (sourceFilters ?? this.sourceFilters),
      presetFilters: forceNullPresets
          ? null
          : (presetFilters ?? this.presetFilters),
      minValueFilter: forceNullMinValue
          ? null
          : (minValueFilter ?? this.minValueFilter),
      maxValueFilter: forceNullMaxValue
          ? null
          : (maxValueFilter ?? this.maxValueFilter),
      selectedAssets: selectedAssets ?? this.selectedAssets,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
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
    nameFilter,
    assetTypeFilters,
    descriptionFilter,
    currencyCodeFilters,
    sourceFilters,
    presetFilters,
    minValueFilter,
    maxValueFilter,
    selectedAssets,
    isSelectionModeActive,
  ];
}
