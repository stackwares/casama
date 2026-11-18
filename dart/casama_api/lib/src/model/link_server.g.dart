// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_server.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkServerCWProxy {
  LinkServer id(String id);

  LinkServer instanceName(String instanceName);

  LinkServer address(String address);

  LinkServer pagesAddress(String pagesAddress);

  LinkServer status(String status);

  LinkServer statusReason(String? statusReason);

  LinkServer platform(String? platform);

  LinkServer version(String? version);

  LinkServer lastSeenAt(DateTime? lastSeenAt);

  LinkServer createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkServer(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkServer call({
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
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkServer.copyWith(...)` or call `instanceOfLinkServer.copyWith.fieldName(value)` for a single field.
class _$LinkServerCWProxyImpl implements _$LinkServerCWProxy {
  const _$LinkServerCWProxyImpl(this._value);

  final LinkServer _value;

  @override
  LinkServer id(String id) => call(id: id);

  @override
  LinkServer instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  LinkServer address(String address) => call(address: address);

  @override
  LinkServer pagesAddress(String pagesAddress) =>
      call(pagesAddress: pagesAddress);

  @override
  LinkServer status(String status) => call(status: status);

  @override
  LinkServer statusReason(String? statusReason) =>
      call(statusReason: statusReason);

  @override
  LinkServer platform(String? platform) => call(platform: platform);

  @override
  LinkServer version(String? version) => call(version: version);

  @override
  LinkServer lastSeenAt(DateTime? lastSeenAt) => call(lastSeenAt: lastSeenAt);

  @override
  LinkServer createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkServer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkServer call({
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
  }) {
    return LinkServer(
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
    );
  }
}

extension $LinkServerCopyWith on LinkServer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkServer.copyWith(...)` or `instanceOfLinkServer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkServerCWProxy get copyWith => _$LinkServerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkServer _$LinkServerFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LinkServer',
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
      ],
    );
    final val = LinkServer(
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
    );
    return val;
  },
  fieldKeyMap: const {
    'instanceName': 'instance_name',
    'pagesAddress': 'pages_address',
    'statusReason': 'status_reason',
    'lastSeenAt': 'last_seen_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$LinkServerToJson(LinkServer instance) =>
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
    };
