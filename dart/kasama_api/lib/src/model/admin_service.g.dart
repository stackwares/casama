// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_service.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminServiceCWProxy {
  AdminService name(String name);

  AdminService configured(bool configured);

  AdminService healthy(bool? healthy);

  AdminService detail(String detail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminService(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminService(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminService call({
    String name,
    bool configured,
    bool? healthy,
    String detail,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminService.copyWith(...)` or call `instanceOfAdminService.copyWith.fieldName(value)` for a single field.
class _$AdminServiceCWProxyImpl implements _$AdminServiceCWProxy {
  const _$AdminServiceCWProxyImpl(this._value);

  final AdminService _value;

  @override
  AdminService name(String name) => call(name: name);

  @override
  AdminService configured(bool configured) => call(configured: configured);

  @override
  AdminService healthy(bool? healthy) => call(healthy: healthy);

  @override
  AdminService detail(String detail) => call(detail: detail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminService(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminService(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminService call({
    Object? name = const $CopyWithPlaceholder(),
    Object? configured = const $CopyWithPlaceholder(),
    Object? healthy = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
  }) {
    return AdminService(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      configured:
          configured == const $CopyWithPlaceholder() || configured == null
          ? _value.configured
          // ignore: cast_nullable_to_non_nullable
          : configured as bool,
      healthy: healthy == const $CopyWithPlaceholder()
          ? _value.healthy
          // ignore: cast_nullable_to_non_nullable
          : healthy as bool?,
      detail: detail == const $CopyWithPlaceholder() || detail == null
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String,
    );
  }
}

extension $AdminServiceCopyWith on AdminService {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminService.copyWith(...)` or `instanceOfAdminService.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminServiceCWProxy get copyWith => _$AdminServiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminService _$AdminServiceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminService', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['name', 'configured', 'healthy', 'detail'],
      );
      final val = AdminService(
        name: $checkedConvert('name', (v) => v as String),
        configured: $checkedConvert('configured', (v) => v as bool),
        healthy: $checkedConvert('healthy', (v) => v as bool?),
        detail: $checkedConvert('detail', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdminServiceToJson(AdminService instance) =>
    <String, dynamic>{
      'name': instance.name,
      'configured': instance.configured,
      'healthy': instance.healthy,
      'detail': instance.detail,
    };
