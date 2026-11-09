// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotListCWProxy {
  BotList items(List<Bot> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BotList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BotList(...).copyWith(id: 12, name: "My name")
  /// ````
  BotList call({List<Bot> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBotList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBotList.copyWith.fieldName(...)`
class _$BotListCWProxyImpl implements _$BotListCWProxy {
  const _$BotListCWProxyImpl(this._value);

  final BotList _value;

  @override
  BotList items(List<Bot> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BotList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BotList(...).copyWith(id: 12, name: "My name")
  /// ````
  BotList call({Object? items = const $CopyWithPlaceholder()}) {
    return BotList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Bot>,
    );
  }
}

extension $BotListCopyWith on BotList {
  /// Returns a callable class that can be used as follows: `instanceOfBotList.copyWith(...)` or like so:`instanceOfBotList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotListCWProxy get copyWith => _$BotListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotList _$BotListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = BotList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Bot.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BotListToJson(BotList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
