// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_domain.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDomainCWProxy {
  AdminDomain id(String id);

  AdminDomain name(String name);

  AdminDomain kind(String kind);

  AdminDomain orgId(String? orgId);

  AdminDomain orgName(String? orgName);

  AdminDomain registrarStatus(String? registrarStatus);

  AdminDomain expiresAt(DateTime? expiresAt);

  AdminDomain suspended(bool suspended);

  AdminDomain createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomain(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomain(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDomain call({
    String id,
    String name,
    String kind,
    String? orgId,
    String? orgName,
    String? registrarStatus,
    DateTime? expiresAt,
    bool suspended,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDomain.copyWith(...)` or call `instanceOfAdminDomain.copyWith.fieldName(value)` for a single field.
class _$AdminDomainCWProxyImpl implements _$AdminDomainCWProxy {
  const _$AdminDomainCWProxyImpl(this._value);

  final AdminDomain _value;

  @override
  AdminDomain id(String id) => call(id: id);

  @override
  AdminDomain name(String name) => call(name: name);

  @override
  AdminDomain kind(String kind) => call(kind: kind);

  @override
  AdminDomain orgId(String? orgId) => call(orgId: orgId);

  @override
  AdminDomain orgName(String? orgName) => call(orgName: orgName);

  @override
  AdminDomain registrarStatus(String? registrarStatus) =>
      call(registrarStatus: registrarStatus);

  @override
  AdminDomain expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  AdminDomain suspended(bool suspended) => call(suspended: suspended);

  @override
  AdminDomain createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomain(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomain(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDomain call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? registrarStatus = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? suspended = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return AdminDomain(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String?,
      orgName: orgName == const $CopyWithPlaceholder()
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String?,
      registrarStatus: registrarStatus == const $CopyWithPlaceholder()
          ? _value.registrarStatus
          // ignore: cast_nullable_to_non_nullable
          : registrarStatus as String?,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      suspended: suspended == const $CopyWithPlaceholder() || suspended == null
          ? _value.suspended
          // ignore: cast_nullable_to_non_nullable
          : suspended as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $AdminDomainCopyWith on AdminDomain {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDomain.copyWith(...)` or `instanceOfAdminDomain.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDomainCWProxy get copyWith => _$AdminDomainCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDomain _$AdminDomainFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminDomain',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'kind',
        'org_id',
        'org_name',
        'registrar_status',
        'expires_at',
        'suspended',
        'created_at',
      ],
    );
    final val = AdminDomain(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      kind: $checkedConvert('kind', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String?),
      orgName: $checkedConvert('org_name', (v) => v as String?),
      registrarStatus: $checkedConvert('registrar_status', (v) => v as String?),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      suspended: $checkedConvert('suspended', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'orgName': 'org_name',
    'registrarStatus': 'registrar_status',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$AdminDomainToJson(AdminDomain instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': instance.kind,
      'org_id': instance.orgId,
      'org_name': instance.orgName,
      'registrar_status': instance.registrarStatus,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'suspended': instance.suspended,
      'created_at': instance.createdAt.toIso8601String(),
    };
