// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_link_server.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminLinkServerCWProxy {
  AdminLinkServer id(String id);

  AdminLinkServer instanceName(String instanceName);

  AdminLinkServer address(String address);

  AdminLinkServer pagesAddress(String pagesAddress);

  AdminLinkServer status(String status);

  AdminLinkServer statusReason(String? statusReason);

  AdminLinkServer platform(String? platform);

  AdminLinkServer version(String? version);

  AdminLinkServer lastSeenAt(DateTime? lastSeenAt);

  AdminLinkServer createdAt(DateTime createdAt);

  AdminLinkServer orgId(String orgId);

  AdminLinkServer orgName(String orgName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLinkServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLinkServer(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminLinkServer call({
    String id,
    String instanceName,
    String address,
    String pagesAddress,
    String status,
    String? statusReason,
    String? platform,
    String? version,
    DateTime? lastSeenAt,
    DateTime createdAt,
    String orgId,
    String orgName,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminLinkServer.copyWith(...)` or call `instanceOfAdminLinkServer.copyWith.fieldName(value)` for a single field.
class _$AdminLinkServerCWProxyImpl implements _$AdminLinkServerCWProxy {
  const _$AdminLinkServerCWProxyImpl(this._value);

  final AdminLinkServer _value;

  @override
  AdminLinkServer id(String id) => call(id: id);

  @override
  AdminLinkServer instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  AdminLinkServer address(String address) => call(address: address);

  @override
  AdminLinkServer pagesAddress(String pagesAddress) =>
      call(pagesAddress: pagesAddress);

  @override
  AdminLinkServer status(String status) => call(status: status);

  @override
  AdminLinkServer statusReason(String? statusReason) =>
      call(statusReason: statusReason);

  @override
  AdminLinkServer platform(String? platform) => call(platform: platform);

  @override
  AdminLinkServer version(String? version) => call(version: version);

  @override
  AdminLinkServer lastSeenAt(DateTime? lastSeenAt) =>
      call(lastSeenAt: lastSeenAt);

  @override
  AdminLinkServer createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  AdminLinkServer orgId(String orgId) => call(orgId: orgId);

  @override
  AdminLinkServer orgName(String orgName) => call(orgName: orgName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminLinkServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminLinkServer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminLinkServer call({
    Object? id = const $CopyWithPlaceholder(),
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? pagesAddress = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? statusReason = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
  }) {
    return AdminLinkServer(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      instanceName:
          instanceName == const $CopyWithPlaceholder() || instanceName == null
          ? _value.instanceName
          // ignore: cast_nullable_to_non_nullable
          : instanceName as String,
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      pagesAddress:
          pagesAddress == const $CopyWithPlaceholder() || pagesAddress == null
          ? _value.pagesAddress
          // ignore: cast_nullable_to_non_nullable
          : pagesAddress as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      statusReason: statusReason == const $CopyWithPlaceholder()
          ? _value.statusReason
          // ignore: cast_nullable_to_non_nullable
          : statusReason as String?,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String?,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String?,
      lastSeenAt: lastSeenAt == const $CopyWithPlaceholder()
          ? _value.lastSeenAt
          // ignore: cast_nullable_to_non_nullable
          : lastSeenAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      orgName: orgName == const $CopyWithPlaceholder() || orgName == null
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String,
    );
  }
}

extension $AdminLinkServerCopyWith on AdminLinkServer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminLinkServer.copyWith(...)` or `instanceOfAdminLinkServer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminLinkServerCWProxy get copyWith => _$AdminLinkServerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLinkServer _$AdminLinkServerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminLinkServer',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'instance_name',
            'address',
            'pages_address',
            'status',
            'status_reason',
            'platform',
            'version',
            'last_seen_at',
            'created_at',
            'org_id',
            'org_name',
          ],
        );
        final val = AdminLinkServer(
          id: $checkedConvert('id', (v) => v as String),
          instanceName: $checkedConvert('instance_name', (v) => v as String),
          address: $checkedConvert('address', (v) => v as String),
          pagesAddress: $checkedConvert('pages_address', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          statusReason: $checkedConvert('status_reason', (v) => v as String?),
          platform: $checkedConvert('platform', (v) => v as String?),
          version: $checkedConvert('version', (v) => v as String?),
          lastSeenAt: $checkedConvert(
            'last_seen_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          orgId: $checkedConvert('org_id', (v) => v as String),
          orgName: $checkedConvert('org_name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'instanceName': 'instance_name',
        'pagesAddress': 'pages_address',
        'statusReason': 'status_reason',
        'lastSeenAt': 'last_seen_at',
        'createdAt': 'created_at',
        'orgId': 'org_id',
        'orgName': 'org_name',
      },
    );

Map<String, dynamic> _$AdminLinkServerToJson(AdminLinkServer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'instance_name': instance.instanceName,
      'address': instance.address,
      'pages_address': instance.pagesAddress,
      'status': instance.status,
      'status_reason': instance.statusReason,
      'platform': instance.platform,
      'version': instance.version,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'org_id': instance.orgId,
      'org_name': instance.orgName,
    };
