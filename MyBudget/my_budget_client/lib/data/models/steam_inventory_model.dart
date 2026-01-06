import 'package:json_annotation/json_annotation.dart';

part 'steam_inventory_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SteamInventoryResponse {
  final List<Asset> assets;
  final List<Description> descriptions;
  final int totalInventoryCount;
  final int success;

  SteamInventoryResponse({
    required this.assets,
    required this.descriptions,
    required this.totalInventoryCount,
    required this.success,
  });

  factory SteamInventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$SteamInventoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SteamInventoryResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Asset {
  final int appid;
  final String contextid;
  final String assetid;
  final String classid;
  final String instanceid;
  final String amount;

  Asset({
    required this.appid,
    required this.contextid,
    required this.assetid,
    required this.classid,
    required this.instanceid,
    required this.amount,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);

  Map<String, dynamic> toJson() => _$AssetToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Description {
  final int appid;
  final String classid;
  final String instanceid;
  final int currency;
  final String backgroundColor;
  final String iconUrl;
  final List<DescriptionItem> descriptions;
  final int tradable;
  final List<Action>? actions;
  final String name;
  final String nameColor;
  final String type;
  final String marketName;
  final String marketHashName;
  final List<MarketAction>? marketActions;
  final int commodity;
  final int marketTradableRestriction;
  final int marketMarketableRestriction;
  final int marketable;
  final List<Tag> tags;

  Description({
    required this.appid,
    required this.classid,
    required this.instanceid,
    required this.currency,
    required this.backgroundColor,
    required this.iconUrl,
    required this.descriptions,
    required this.tradable,
    this.actions,
    required this.name,
    required this.nameColor,
    required this.type,
    required this.marketName,
    required this.marketHashName,
    this.marketActions,
    required this.commodity,
    required this.marketTradableRestriction,
    required this.marketMarketableRestriction,
    required this.marketable,
    required this.tags,
  });

  factory Description.fromJson(Map<String, dynamic> json) =>
      _$DescriptionFromJson(json);

  Map<String, dynamic> toJson() => _$DescriptionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DescriptionItem {
  final String type;
  final String value;
  final String? color;
  final String? name;

  DescriptionItem({
    required this.type,
    required this.value,
    this.color,
    this.name
  });

  factory DescriptionItem.fromJson(Map<String, dynamic> json) =>
      _$DescriptionItemFromJson(json);

  Map<String, dynamic> toJson() => _$DescriptionItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Action {
  final String link;
  final String name;

  Action({
    required this.link,
    required this.name,
  });

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);

  Map<String, dynamic> toJson() => _$ActionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MarketAction {
  final String link;
  final String name;

  MarketAction({
    required this.link,
    required this.name,
  });

  factory MarketAction.fromJson(Map<String, dynamic> json) =>
      _$MarketActionFromJson(json);

  Map<String, dynamic> toJson() => _$MarketActionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Tag {
  final String category;
  final String internalName;
  final String localizedCategoryName;
  final String localizedTagName;
  final String? color;


  Tag({
    required this.category,
    required this.internalName,
    required this.localizedCategoryName,
    required this.localizedTagName,
    this.color,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class BulkPricesResponse {
  final Map<String, ItemPrice> items;

  BulkPricesResponse({required this.items});

  factory BulkPricesResponse.fromJson(Map<String, dynamic> json) =>
      _$BulkPricesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BulkPricesResponseToJson(this);
}


@JsonSerializable(fieldRename: FieldRename.snake)
class ItemPrice {
  final bool success;
  final double? lowestPrice;
  final double? medianPrice;
  final int? volume;

  ItemPrice({
    required this.success,
    this.lowestPrice,
    this.medianPrice,
    this.volume,
  });

  factory ItemPrice.fromJson(Map<String, dynamic> json) =>
      _$ItemPriceFromJson(json);

  Map<String, dynamic> toJson() => _$ItemPriceToJson(this);
}
