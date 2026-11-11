// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_event_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChannelEventListCWProxy {
  ChannelEventList items(List<ChannelEvent> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChannelEventList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChannelEventList(...).copyWith(id: 12, name: "My name")
  /// ```
  ChannelEventList call({List<ChannelEvent> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChannelEventList.copyWith(...)` or call `instanceOfChannelEventList.copyWith.fieldName(value)` for a single field.
class _$ChannelEventListCWProxyImpl implements _$ChannelEventListCWProxy {
  const _$ChannelEventListCWProxyImpl(this._value);

  final ChannelEventList _value;

  @override
  ChannelEventList items(List<ChannelEvent> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChannelEventList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChannelEventList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChannelEventList call({Object? items = const $CopyWithPlaceholder()}) {
    return ChannelEventList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ChannelEvent>,
    );
  }
}

extension $ChannelEventListCopyWith on ChannelEventList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChannelEventList.copyWith(...)` or `instanceOfChannelEventList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChannelEventListCWProxy get copyWith => _$ChannelEventListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelEventList _$ChannelEventListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChannelEventList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ChannelEventList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ChannelEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ChannelEventListToJson(ChannelEventList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
