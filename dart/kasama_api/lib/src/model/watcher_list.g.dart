// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watcher_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatcherListCWProxy {
  WatcherList items(List<Watcher> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatcherList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatcherList(...).copyWith(id: 12, name: "My name")
  /// ```
  WatcherList call({List<Watcher> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatcherList.copyWith(...)` or call `instanceOfWatcherList.copyWith.fieldName(value)` for a single field.
class _$WatcherListCWProxyImpl implements _$WatcherListCWProxy {
  const _$WatcherListCWProxyImpl(this._value);

  final WatcherList _value;

  @override
  WatcherList items(List<Watcher> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatcherList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatcherList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatcherList call({Object? items = const $CopyWithPlaceholder()}) {
    return WatcherList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Watcher>,
    );
  }
}

extension $WatcherListCopyWith on WatcherList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatcherList.copyWith(...)` or `instanceOfWatcherList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatcherListCWProxy get copyWith => _$WatcherListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatcherList _$WatcherListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatcherList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = WatcherList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Watcher.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WatcherListToJson(WatcherList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
