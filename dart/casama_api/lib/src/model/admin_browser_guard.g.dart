// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_browser_guard.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminBrowserGuardCWProxy {
  AdminBrowserGuard hosts(Map<String, List<String>> hosts);

  AdminBrowserGuard builtIn(Map<String, List<String>> builtIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminBrowserGuard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminBrowserGuard(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminBrowserGuard call({
    Map<String, List<String>> hosts,
    Map<String, List<String>> builtIn,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminBrowserGuard.copyWith(...)` or call `instanceOfAdminBrowserGuard.copyWith.fieldName(value)` for a single field.
class _$AdminBrowserGuardCWProxyImpl implements _$AdminBrowserGuardCWProxy {
  const _$AdminBrowserGuardCWProxyImpl(this._value);

  final AdminBrowserGuard _value;

  @override
  AdminBrowserGuard hosts(Map<String, List<String>> hosts) =>
      call(hosts: hosts);

  @override
  AdminBrowserGuard builtIn(Map<String, List<String>> builtIn) =>
      call(builtIn: builtIn);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminBrowserGuard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminBrowserGuard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminBrowserGuard call({
    Object? hosts = const $CopyWithPlaceholder(),
    Object? builtIn = const $CopyWithPlaceholder(),
  }) {
    return AdminBrowserGuard(
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as Map<String, List<String>>,
      builtIn: builtIn == const $CopyWithPlaceholder() || builtIn == null
          ? _value.builtIn
          // ignore: cast_nullable_to_non_nullable
          : builtIn as Map<String, List<String>>,
    );
  }
}

extension $AdminBrowserGuardCopyWith on AdminBrowserGuard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminBrowserGuard.copyWith(...)` or `instanceOfAdminBrowserGuard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminBrowserGuardCWProxy get copyWith =>
      _$AdminBrowserGuardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminBrowserGuard _$AdminBrowserGuardFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminBrowserGuard', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['hosts', 'built_in']);
  final val = AdminBrowserGuard(
    hosts: $checkedConvert(
      'hosts',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    ),
    builtIn: $checkedConvert(
      'built_in',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    ),
  );
  return val;
}, fieldKeyMap: const {'builtIn': 'built_in'});

Map<String, dynamic> _$AdminBrowserGuardToJson(AdminBrowserGuard instance) =>
    <String, dynamic>{'hosts': instance.hosts, 'built_in': instance.builtIn};
