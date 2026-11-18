// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainCWProxy {
  Domain id(String id);

  Domain name(String name);

  Domain kind(String kind);

  Domain target(String target);

  Domain dnsProvider(String? dnsProvider);

  Domain dnsProviderName(String? dnsProviderName);

  Domain pageId(String? pageId);

  Domain pageTitle(String? pageTitle);

  Domain state(String state);

  Domain live(bool live);

  Domain hosts(List<SiteHost> hosts);

  Domain records(List<DomainRecord> records);

  Domain expiresAt(DateTime? expiresAt);

  Domain autoRenew(bool autoRenew);

  Domain registrarStatus(String? registrarStatus);

  Domain renewPriceUsd(num? renewPriceUsd);

  Domain locked(bool locked);

  Domain transferAfter(DateTime? transferAfter);

  Domain registrantVerified(bool? registrantVerified);

  Domain checkedAt(DateTime? checkedAt);

  Domain createdAt(DateTime createdAt);

  Domain events(List<DomainEvent>? events);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Domain(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Domain(...).copyWith(id: 12, name: "My name")
  /// ```
  Domain call({
    String id,
    String name,
    String kind,
    String target,
    String? dnsProvider,
    String? dnsProviderName,
    String? pageId,
    String? pageTitle,
    String state,
    bool live,
    List<SiteHost> hosts,
    List<DomainRecord> records,
    DateTime? expiresAt,
    bool autoRenew,
    String? registrarStatus,
    num? renewPriceUsd,
    bool locked,
    DateTime? transferAfter,
    bool? registrantVerified,
    DateTime? checkedAt,
    DateTime createdAt,
    List<DomainEvent>? events,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomain.copyWith(...)` or call `instanceOfDomain.copyWith.fieldName(value)` for a single field.
class _$DomainCWProxyImpl implements _$DomainCWProxy {
  const _$DomainCWProxyImpl(this._value);

  final Domain _value;

  @override
  Domain id(String id) => call(id: id);

  @override
  Domain name(String name) => call(name: name);

  @override
  Domain kind(String kind) => call(kind: kind);

  @override
  Domain target(String target) => call(target: target);

  @override
  Domain dnsProvider(String? dnsProvider) => call(dnsProvider: dnsProvider);

  @override
  Domain dnsProviderName(String? dnsProviderName) =>
      call(dnsProviderName: dnsProviderName);

  @override
  Domain pageId(String? pageId) => call(pageId: pageId);

  @override
  Domain pageTitle(String? pageTitle) => call(pageTitle: pageTitle);

  @override
  Domain state(String state) => call(state: state);

  @override
  Domain live(bool live) => call(live: live);

  @override
  Domain hosts(List<SiteHost> hosts) => call(hosts: hosts);

  @override
  Domain records(List<DomainRecord> records) => call(records: records);

  @override
  Domain expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  Domain autoRenew(bool autoRenew) => call(autoRenew: autoRenew);

  @override
  Domain registrarStatus(String? registrarStatus) =>
      call(registrarStatus: registrarStatus);

  @override
  Domain renewPriceUsd(num? renewPriceUsd) =>
      call(renewPriceUsd: renewPriceUsd);

  @override
  Domain locked(bool locked) => call(locked: locked);

  @override
  Domain transferAfter(DateTime? transferAfter) =>
      call(transferAfter: transferAfter);

  @override
  Domain registrantVerified(bool? registrantVerified) =>
      call(registrantVerified: registrantVerified);

  @override
  Domain checkedAt(DateTime? checkedAt) => call(checkedAt: checkedAt);

  @override
  Domain createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Domain events(List<DomainEvent>? events) => call(events: events);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Domain(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Domain(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Domain call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
    Object? dnsProvider = const $CopyWithPlaceholder(),
    Object? dnsProviderName = const $CopyWithPlaceholder(),
    Object? pageId = const $CopyWithPlaceholder(),
    Object? pageTitle = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? live = const $CopyWithPlaceholder(),
    Object? hosts = const $CopyWithPlaceholder(),
    Object? records = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? autoRenew = const $CopyWithPlaceholder(),
    Object? registrarStatus = const $CopyWithPlaceholder(),
    Object? renewPriceUsd = const $CopyWithPlaceholder(),
    Object? locked = const $CopyWithPlaceholder(),
    Object? transferAfter = const $CopyWithPlaceholder(),
    Object? registrantVerified = const $CopyWithPlaceholder(),
    Object? checkedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? events = const $CopyWithPlaceholder(),
  }) {
    return Domain(
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
      target: target == const $CopyWithPlaceholder() || target == null
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as String,
      dnsProvider: dnsProvider == const $CopyWithPlaceholder()
          ? _value.dnsProvider
          // ignore: cast_nullable_to_non_nullable
          : dnsProvider as String?,
      dnsProviderName: dnsProviderName == const $CopyWithPlaceholder()
          ? _value.dnsProviderName
          // ignore: cast_nullable_to_non_nullable
          : dnsProviderName as String?,
      pageId: pageId == const $CopyWithPlaceholder()
          ? _value.pageId
          // ignore: cast_nullable_to_non_nullable
          : pageId as String?,
      pageTitle: pageTitle == const $CopyWithPlaceholder()
          ? _value.pageTitle
          // ignore: cast_nullable_to_non_nullable
          : pageTitle as String?,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as String,
      live: live == const $CopyWithPlaceholder() || live == null
          ? _value.live
          // ignore: cast_nullable_to_non_nullable
          : live as bool,
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as List<SiteHost>,
      records: records == const $CopyWithPlaceholder() || records == null
          ? _value.records
          // ignore: cast_nullable_to_non_nullable
          : records as List<DomainRecord>,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      autoRenew: autoRenew == const $CopyWithPlaceholder() || autoRenew == null
          ? _value.autoRenew
          // ignore: cast_nullable_to_non_nullable
          : autoRenew as bool,
      registrarStatus: registrarStatus == const $CopyWithPlaceholder()
          ? _value.registrarStatus
          // ignore: cast_nullable_to_non_nullable
          : registrarStatus as String?,
      renewPriceUsd: renewPriceUsd == const $CopyWithPlaceholder()
          ? _value.renewPriceUsd
          // ignore: cast_nullable_to_non_nullable
          : renewPriceUsd as num?,
      locked: locked == const $CopyWithPlaceholder() || locked == null
          ? _value.locked
          // ignore: cast_nullable_to_non_nullable
          : locked as bool,
      transferAfter: transferAfter == const $CopyWithPlaceholder()
          ? _value.transferAfter
          // ignore: cast_nullable_to_non_nullable
          : transferAfter as DateTime?,
      registrantVerified: registrantVerified == const $CopyWithPlaceholder()
          ? _value.registrantVerified
          // ignore: cast_nullable_to_non_nullable
          : registrantVerified as bool?,
      checkedAt: checkedAt == const $CopyWithPlaceholder()
          ? _value.checkedAt
          // ignore: cast_nullable_to_non_nullable
          : checkedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      events: events == const $CopyWithPlaceholder()
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<DomainEvent>?,
    );
  }
}

extension $DomainCopyWith on Domain {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomain.copyWith(...)` or `instanceOfDomain.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainCWProxy get copyWith => _$DomainCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Domain _$DomainFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Domain',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'kind',
        'target',
        'dns_provider',
        'page_id',
        'page_title',
        'state',
        'live',
        'hosts',
        'records',
        'expires_at',
        'auto_renew',
        'registrar_status',
        'renew_price_usd',
        'locked',
        'transfer_after',
        'registrant_verified',
        'checked_at',
        'created_at',
      ],
    );
    final val = Domain(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      kind: $checkedConvert('kind', (v) => v as String),
      target: $checkedConvert('target', (v) => v as String),
      dnsProvider: $checkedConvert('dns_provider', (v) => v as String?),
      dnsProviderName: $checkedConvert(
        'dns_provider_name',
        (v) => v as String?,
      ),
      pageId: $checkedConvert('page_id', (v) => v as String?),
      pageTitle: $checkedConvert('page_title', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String),
      live: $checkedConvert('live', (v) => v as bool),
      hosts: $checkedConvert(
        'hosts',
        (v) => (v as List<dynamic>)
            .map((e) => SiteHost.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      records: $checkedConvert(
        'records',
        (v) => (v as List<dynamic>)
            .map((e) => DomainRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      autoRenew: $checkedConvert('auto_renew', (v) => v as bool),
      registrarStatus: $checkedConvert('registrar_status', (v) => v as String?),
      renewPriceUsd: $checkedConvert('renew_price_usd', (v) => v as num?),
      locked: $checkedConvert('locked', (v) => v as bool),
      transferAfter: $checkedConvert(
        'transfer_after',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      registrantVerified: $checkedConvert(
        'registrant_verified',
        (v) => v as bool?,
      ),
      checkedAt: $checkedConvert(
        'checked_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      events: $checkedConvert(
        'events',
        (v) => (v as List<dynamic>?)
            ?.map((e) => DomainEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'dnsProvider': 'dns_provider',
    'dnsProviderName': 'dns_provider_name',
    'pageId': 'page_id',
    'pageTitle': 'page_title',
    'expiresAt': 'expires_at',
    'autoRenew': 'auto_renew',
    'registrarStatus': 'registrar_status',
    'renewPriceUsd': 'renew_price_usd',
    'transferAfter': 'transfer_after',
    'registrantVerified': 'registrant_verified',
    'checkedAt': 'checked_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$DomainToJson(Domain instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'kind': instance.kind,
  'target': instance.target,
  'dns_provider': instance.dnsProvider,
  'dns_provider_name': ?instance.dnsProviderName,
  'page_id': instance.pageId,
  'page_title': instance.pageTitle,
  'state': instance.state,
  'live': instance.live,
  'hosts': instance.hosts.map((e) => e.toJson()).toList(),
  'records': instance.records.map((e) => e.toJson()).toList(),
  'expires_at': instance.expiresAt?.toIso8601String(),
  'auto_renew': instance.autoRenew,
  'registrar_status': instance.registrarStatus,
  'renew_price_usd': instance.renewPriceUsd,
  'locked': instance.locked,
  'transfer_after': instance.transferAfter?.toIso8601String(),
  'registrant_verified': instance.registrantVerified,
  'checked_at': instance.checkedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'events': ?instance.events?.map((e) => e.toJson()).toList(),
};
