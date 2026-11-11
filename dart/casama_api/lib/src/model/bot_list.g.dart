// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotListCWProxy {
  BotList items(List<Bot> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotList(...).copyWith(id: 12, name: "My name")
  /// ```
  BotList call({List<Bot> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotList.copyWith(...)` or call `instanceOfBotList.copyWith.fieldName(value)` for a single field.
class _$BotListCWProxyImpl implements _$BotListCWProxy {
  const _$BotListCWProxyImpl(this._value);

  final BotList _value;

  @override
  BotList items(List<Bot> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotList call({Object? items = const $CopyWithPlaceholder()}) {
    return BotList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Bot>,
    );
  }
}

extension $BotListCopyWith on BotList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotList.copyWith(...)` or `instanceOfBotList.copyWith.fieldName(...)`.
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
