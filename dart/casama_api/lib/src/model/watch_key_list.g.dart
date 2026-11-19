// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_key_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchKeyListCWProxy {
  WatchKeyList items(List<WatchKey> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchKeyList call({List<WatchKey> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchKeyList.copyWith(...)` or call `instanceOfWatchKeyList.copyWith.fieldName(value)` for a single field.
class _$WatchKeyListCWProxyImpl implements _$WatchKeyListCWProxy {
  const _$WatchKeyListCWProxyImpl(this._value);

  final WatchKeyList _value;

  @override
  WatchKeyList items(List<WatchKey> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchKeyList call({Object? items = const $CopyWithPlaceholder()}) {
    return WatchKeyList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<WatchKey>,
    );
  }
}

extension $WatchKeyListCopyWith on WatchKeyList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchKeyList.copyWith(...)` or `instanceOfWatchKeyList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchKeyListCWProxy get copyWith => _$WatchKeyListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchKeyList _$WatchKeyListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchKeyList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = WatchKeyList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => WatchKey.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WatchKeyListToJson(WatchKeyList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
