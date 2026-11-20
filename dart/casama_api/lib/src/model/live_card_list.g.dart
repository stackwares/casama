// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_card_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LiveCardListCWProxy {
  LiveCardList items(List<LiveCard> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LiveCardList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LiveCardList(...).copyWith(id: 12, name: "My name")
  /// ```
  LiveCardList call({List<LiveCard> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLiveCardList.copyWith(...)` or call `instanceOfLiveCardList.copyWith.fieldName(value)` for a single field.
class _$LiveCardListCWProxyImpl implements _$LiveCardListCWProxy {
  const _$LiveCardListCWProxyImpl(this._value);

  final LiveCardList _value;

  @override
  LiveCardList items(List<LiveCard> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LiveCardList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LiveCardList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LiveCardList call({Object? items = const $CopyWithPlaceholder()}) {
    return LiveCardList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LiveCard>,
    );
  }
}

extension $LiveCardListCopyWith on LiveCardList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLiveCardList.copyWith(...)` or `instanceOfLiveCardList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LiveCardListCWProxy get copyWith => _$LiveCardListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveCardList _$LiveCardListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LiveCardList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = LiveCardList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LiveCard.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LiveCardListToJson(LiveCardList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
