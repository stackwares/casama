// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_host.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteHostCWProxy {
  SiteHost id(String id);

  SiteHost hostname(String hostname);

  SiteHost kind(String kind);

  SiteHost isPrimary(bool isPrimary);

  SiteHost status(String status);

  SiteHost statusReason(String? statusReason);

  SiteHost domainId(String? domainId);

  SiteHost live(bool live);

  SiteHost url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteHost(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteHost(...).copyWith(id: 12, name: "My name")
  /// ```
  SiteHost call({
    String id,
    String hostname,
    String kind,
    bool isPrimary,
    String status,
    String? statusReason,
    String? domainId,
    bool live,
    String url,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSiteHost.copyWith(...)` or call `instanceOfSiteHost.copyWith.fieldName(value)` for a single field.
class _$SiteHostCWProxyImpl implements _$SiteHostCWProxy {
  const _$SiteHostCWProxyImpl(this._value);

  final SiteHost _value;

  @override
  SiteHost id(String id) => call(id: id);

  @override
  SiteHost hostname(String hostname) => call(hostname: hostname);

  @override
  SiteHost kind(String kind) => call(kind: kind);

  @override
  SiteHost isPrimary(bool isPrimary) => call(isPrimary: isPrimary);

  @override
  SiteHost status(String status) => call(status: status);

  @override
  SiteHost statusReason(String? statusReason) =>
      call(statusReason: statusReason);

  @override
  SiteHost domainId(String? domainId) => call(domainId: domainId);

  @override
  SiteHost live(bool live) => call(live: live);

  @override
  SiteHost url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteHost(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteHost(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SiteHost call({
    Object? id = const $CopyWithPlaceholder(),
    Object? hostname = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? isPrimary = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? statusReason = const $CopyWithPlaceholder(),
    Object? domainId = const $CopyWithPlaceholder(),
    Object? live = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return SiteHost(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      hostname: hostname == const $CopyWithPlaceholder() || hostname == null
          ? _value.hostname
          // ignore: cast_nullable_to_non_nullable
          : hostname as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      isPrimary: isPrimary == const $CopyWithPlaceholder() || isPrimary == null
          ? _value.isPrimary
          // ignore: cast_nullable_to_non_nullable
          : isPrimary as bool,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      statusReason: statusReason == const $CopyWithPlaceholder()
          ? _value.statusReason
          // ignore: cast_nullable_to_non_nullable
          : statusReason as String?,
      domainId: domainId == const $CopyWithPlaceholder()
          ? _value.domainId
          // ignore: cast_nullable_to_non_nullable
          : domainId as String?,
      live: live == const $CopyWithPlaceholder() || live == null
          ? _value.live
          // ignore: cast_nullable_to_non_nullable
          : live as bool,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $SiteHostCopyWith on SiteHost {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSiteHost.copyWith(...)` or `instanceOfSiteHost.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteHostCWProxy get copyWith => _$SiteHostCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteHost _$SiteHostFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SiteHost',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'hostname',
        'kind',
        'is_primary',
        'status',
        'status_reason',
        'domain_id',
        'live',
        'url',
      ],
    );
    final val = SiteHost(
      id: $checkedConvert('id', (v) => v as String),
      hostname: $checkedConvert('hostname', (v) => v as String),
      kind: $checkedConvert('kind', (v) => v as String),
      isPrimary: $checkedConvert('is_primary', (v) => v as bool),
      status: $checkedConvert('status', (v) => v as String),
      statusReason: $checkedConvert('status_reason', (v) => v as String?),
      domainId: $checkedConvert('domain_id', (v) => v as String?),
      live: $checkedConvert('live', (v) => v as bool),
      url: $checkedConvert('url', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'isPrimary': 'is_primary',
    'statusReason': 'status_reason',
    'domainId': 'domain_id',
  },
);

Map<String, dynamic> _$SiteHostToJson(SiteHost instance) => <String, dynamic>{
  'id': instance.id,
  'hostname': instance.hostname,
  'kind': instance.kind,
  'is_primary': instance.isPrimary,
  'status': instance.status,
  'status_reason': instance.statusReason,
  'domain_id': instance.domainId,
  'live': instance.live,
  'url': instance.url,
};
