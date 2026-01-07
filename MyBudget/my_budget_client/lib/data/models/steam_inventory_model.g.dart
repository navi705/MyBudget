// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steam_inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SteamInventoryResponse _$SteamInventoryResponseFromJson(
  Map<String, dynamic> json,
) => SteamInventoryResponse(
  assets: (json['assets'] as List<dynamic>)
      .map((e) => Asset.fromJson(e as Map<String, dynamic>))
      .toList(),
  descriptions: (json['descriptions'] as List<dynamic>)
      .map((e) => Description.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalInventoryCount: (json['total_inventory_count'] as num).toInt(),
  success: (json['success'] as num).toInt(),
);

Map<String, dynamic> _$SteamInventoryResponseToJson(
  SteamInventoryResponse instance,
) => <String, dynamic>{
  'assets': instance.assets,
  'descriptions': instance.descriptions,
  'total_inventory_count': instance.totalInventoryCount,
  'success': instance.success,
};

Asset _$AssetFromJson(Map<String, dynamic> json) => Asset(
  appid: (json['appid'] as num).toInt(),
  contextid: json['contextid'] as String,
  assetid: json['assetid'] as String,
  classid: json['classid'] as String,
  instanceid: json['instanceid'] as String,
  amount: json['amount'] as String,
);

Map<String, dynamic> _$AssetToJson(Asset instance) => <String, dynamic>{
  'appid': instance.appid,
  'contextid': instance.contextid,
  'assetid': instance.assetid,
  'classid': instance.classid,
  'instanceid': instance.instanceid,
  'amount': instance.amount,
};

Description _$DescriptionFromJson(Map<String, dynamic> json) => Description(
  appid: (json['appid'] as num).toInt(),
  classid: json['classid'] as String,
  instanceid: json['instanceid'] as String,
  currency: (json['currency'] as num).toInt(),
  backgroundColor: json['background_color'] as String,
  iconUrl: json['icon_url'] as String,
  descriptions: (json['descriptions'] as List<dynamic>)
      .map((e) => DescriptionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  tradable: (json['tradable'] as num).toInt(),
  actions: (json['actions'] as List<dynamic>?)
      ?.map((e) => Action.fromJson(e as Map<String, dynamic>))
      .toList(),
  name: json['name'] as String,
  nameColor: json['name_color'] as String,
  type: json['type'] as String,
  marketName: json['market_name'] as String,
  marketHashName: json['market_hash_name'] as String,
  marketActions: (json['market_actions'] as List<dynamic>?)
      ?.map((e) => MarketAction.fromJson(e as Map<String, dynamic>))
      .toList(),
  commodity: (json['commodity'] as num).toInt(),
  marketTradableRestriction: (json['market_tradable_restriction'] as num)
      .toInt(),
  marketMarketableRestriction: (json['market_marketable_restriction'] as num)
      .toInt(),
  marketable: (json['marketable'] as num).toInt(),
  tags: (json['tags'] as List<dynamic>)
      .map((e) => Tag.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DescriptionToJson(Description instance) =>
    <String, dynamic>{
      'appid': instance.appid,
      'classid': instance.classid,
      'instanceid': instance.instanceid,
      'currency': instance.currency,
      'background_color': instance.backgroundColor,
      'icon_url': instance.iconUrl,
      'descriptions': instance.descriptions,
      'tradable': instance.tradable,
      'actions': instance.actions,
      'name': instance.name,
      'name_color': instance.nameColor,
      'type': instance.type,
      'market_name': instance.marketName,
      'market_hash_name': instance.marketHashName,
      'market_actions': instance.marketActions,
      'commodity': instance.commodity,
      'market_tradable_restriction': instance.marketTradableRestriction,
      'market_marketable_restriction': instance.marketMarketableRestriction,
      'marketable': instance.marketable,
      'tags': instance.tags,
    };

DescriptionItem _$DescriptionItemFromJson(Map<String, dynamic> json) =>
    DescriptionItem(
      type: json['type'] as String,
      value: json['value'] as String,
      color: json['color'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$DescriptionItemToJson(DescriptionItem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'color': instance.color,
      'name': instance.name,
    };

Action _$ActionFromJson(Map<String, dynamic> json) =>
    Action(link: json['link'] as String, name: json['name'] as String);

Map<String, dynamic> _$ActionToJson(Action instance) => <String, dynamic>{
  'link': instance.link,
  'name': instance.name,
};

MarketAction _$MarketActionFromJson(Map<String, dynamic> json) =>
    MarketAction(link: json['link'] as String, name: json['name'] as String);

Map<String, dynamic> _$MarketActionToJson(MarketAction instance) =>
    <String, dynamic>{'link': instance.link, 'name': instance.name};

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
  category: json['category'] as String,
  internalName: json['internal_name'] as String,
  localizedCategoryName: json['localized_category_name'] as String,
  localizedTagName: json['localized_tag_name'] as String,
  color: json['color'] as String?,
);

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
  'category': instance.category,
  'internal_name': instance.internalName,
  'localized_category_name': instance.localizedCategoryName,
  'localized_tag_name': instance.localizedTagName,
  'color': instance.color,
};

BulkPricesResponse _$BulkPricesResponseFromJson(Map<String, dynamic> json) =>
    BulkPricesResponse(
      items: (json['results'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ItemPrice.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$BulkPricesResponseToJson(BulkPricesResponse instance) =>
    <String, dynamic>{'results': instance.items};

ItemPrice _$ItemPriceFromJson(Map<String, dynamic> json) => ItemPrice(
  success: json['success'] as bool,
  lowestPrice: const PriceToDoubleConverter().fromJson(
    json['lowest_price'] as String?,
  ),
  medianPrice: const PriceToDoubleConverter().fromJson(
    json['median_price'] as String?,
  ),
  volume: json['volume'] as String?,
);

Map<String, dynamic> _$ItemPriceToJson(ItemPrice instance) => <String, dynamic>{
  'success': instance.success,
  'lowest_price': const PriceToDoubleConverter().toJson(instance.lowestPrice),
  'median_price': const PriceToDoubleConverter().toJson(instance.medianPrice),
  'volume': instance.volume,
};
