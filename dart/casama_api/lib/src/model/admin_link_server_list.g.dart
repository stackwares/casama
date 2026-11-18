// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_link_server_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminLinkServerListCWProxy {
  AdminLinkServerList items(List<AdminLinkServer> items);

  AdminLinkServerList tunnels(int? tunnels);

  AdminLinkServerList zone(String zone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLinkServerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLinkServerList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminLinkServerList call({
    List<AdminLinkServer> items,
    int? tunnels,
    String zone,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminLinkServerList.copyWith(...)` or call `instanceOfAdminLinkServerList.copyWith.fieldName(value)` for a single field.
class _$AdminLinkServerListCWProxyImpl implements _$AdminLinkServerListCWProxy {
  const _$AdminLinkServerListCWProxyImpl(this._value);

  final AdminLinkServerList _value;

  @override
  AdminLinkServerList items(List<AdminLinkServer> items) => call(items: items);

  @override
  AdminLinkServerList tunnels(int? tunnels) => call(tunnels: tunnels);

  @override
  AdminLinkServerList zone(String zone) => call(zone: zone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLinkServerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLinkServerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminLinkServerList call({
    Object? items = const $CopyWithPlaceholder(),
    Object? tunnels = const $CopyWithPlaceholder(),
    Object? zone = const $CopyWithPlaceholder(),
  }) {
    return AdminLinkServerList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<AdminLinkServer>,
      tunnels: tunnels == const $CopyWithPlaceholder()
          ? _value.tunnels
          // ignore: cast_nullable_to_non_nullable
          : tunnels as int?,
      zone: zone == const $CopyWithPlaceholder() || zone == null
          ? _value.zone
          // ignore: cast_nullable_to_non_nullable
          : zone as String,
    );
  }
}

extension $AdminLinkServerListCopyWith on AdminLinkServerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminLinkServerList.copyWith(...)` or `instanceOfAdminLinkServerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminLinkServerListCWProxy get copyWith =>
      _$AdminLinkServerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLinkServerList _$AdminLinkServerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminLinkServerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'tunnels', 'zone']);
      final val = AdminLinkServerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => AdminLinkServer.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        tunnels: $checkedConvert('tunnels', (v) => (v as num?)?.toInt()),
        zone: $checkedConvert('zone', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdminLinkServerListToJson(
  AdminLinkServerList instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'tunnels': instance.tunnels,
  'zone': instance.zone,
};
