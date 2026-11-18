// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_server_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkServerListCWProxy {
  LinkServerList items(List<LinkServer> items);

  LinkServerList limit(int limit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkServerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkServerList(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkServerList call({List<LinkServer> items, int limit});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkServerList.copyWith(...)` or call `instanceOfLinkServerList.copyWith.fieldName(value)` for a single field.
class _$LinkServerListCWProxyImpl implements _$LinkServerListCWProxy {
  const _$LinkServerListCWProxyImpl(this._value);

  final LinkServerList _value;

  @override
  LinkServerList items(List<LinkServer> items) => call(items: items);

  @override
  LinkServerList limit(int limit) => call(limit: limit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkServerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkServerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkServerList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? limit = const $CopyWithPlaceholder(),
  }) {
    return LinkServerList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LinkServer>,
      limit: limit == const $CopyWithPlaceholder() || limit == null
          ? _value.limit
          // ignore: cast_nullable_to_non_nullable
          : limit as int,
    );
  }
}

extension $LinkServerListCopyWith on LinkServerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkServerList.copyWith(...)` or `instanceOfLinkServerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkServerListCWProxy get copyWith => _$LinkServerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkServerList _$LinkServerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LinkServerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'limit']);
      final val = LinkServerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LinkServer.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        limit: $checkedConvert('limit', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$LinkServerListToJson(LinkServerList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'limit': instance.limit,
    };
