// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChannelListCWProxy {
  ChannelList items(List<Channel> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChannelList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChannelList(...).copyWith(id: 12, name: "My name")
  /// ```
  ChannelList call({List<Channel> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChannelList.copyWith(...)` or call `instanceOfChannelList.copyWith.fieldName(value)` for a single field.
class _$ChannelListCWProxyImpl implements _$ChannelListCWProxy {
  const _$ChannelListCWProxyImpl(this._value);

  final ChannelList _value;

  @override
  ChannelList items(List<Channel> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChannelList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChannelList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChannelList call({Object? items = const $CopyWithPlaceholder()}) {
    return ChannelList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Channel>,
    );
  }
}

extension $ChannelListCopyWith on ChannelList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChannelList.copyWith(...)` or `instanceOfChannelList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChannelListCWProxy get copyWith => _$ChannelListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelList _$ChannelListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChannelList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ChannelList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Channel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ChannelListToJson(ChannelList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
