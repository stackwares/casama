// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_domains_counts.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDomainsCountsCWProxy {
  AdminDomainsCounts connected(int connected);

  AdminDomainsCounts registered(int registered);

  AdminDomainsCounts liveHosts(int liveHosts);

  AdminDomainsCounts suspended(int suspended);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomainsCounts(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomainsCounts(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDomainsCounts call({
    int connected,
    int registered,
    int liveHosts,
    int suspended,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDomainsCounts.copyWith(...)` or call `instanceOfAdminDomainsCounts.copyWith.fieldName(value)` for a single field.
class _$AdminDomainsCountsCWProxyImpl implements _$AdminDomainsCountsCWProxy {
  const _$AdminDomainsCountsCWProxyImpl(this._value);

  final AdminDomainsCounts _value;

  @override
  AdminDomainsCounts connected(int connected) => call(connected: connected);

  @override
  AdminDomainsCounts registered(int registered) => call(registered: registered);

  @override
  AdminDomainsCounts liveHosts(int liveHosts) => call(liveHosts: liveHosts);

  @override
  AdminDomainsCounts suspended(int suspended) => call(suspended: suspended);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomainsCounts(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomainsCounts(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDomainsCounts call({
    Object? connected = const $CopyWithPlaceholder(),
    Object? registered = const $CopyWithPlaceholder(),
    Object? liveHosts = const $CopyWithPlaceholder(),
    Object? suspended = const $CopyWithPlaceholder(),
  }) {
    return AdminDomainsCounts(
      connected: connected == const $CopyWithPlaceholder() || connected == null
          ? _value.connected
          // ignore: cast_nullable_to_non_nullable
          : connected as int,
      registered:
          registered == const $CopyWithPlaceholder() || registered == null
          ? _value.registered
          // ignore: cast_nullable_to_non_nullable
          : registered as int,
      liveHosts: liveHosts == const $CopyWithPlaceholder() || liveHosts == null
          ? _value.liveHosts
          // ignore: cast_nullable_to_non_nullable
          : liveHosts as int,
      suspended: suspended == const $CopyWithPlaceholder() || suspended == null
          ? _value.suspended
          // ignore: cast_nullable_to_non_nullable
          : suspended as int,
    );
  }
}

extension $AdminDomainsCountsCopyWith on AdminDomainsCounts {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDomainsCounts.copyWith(...)` or `instanceOfAdminDomainsCounts.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDomainsCountsCWProxy get copyWith =>
      _$AdminDomainsCountsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDomainsCounts _$AdminDomainsCountsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDomainsCounts', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'connected',
          'registered',
          'live_hosts',
          'suspended',
        ],
      );
      final val = AdminDomainsCounts(
        connected: $checkedConvert('connected', (v) => (v as num).toInt()),
        registered: $checkedConvert('registered', (v) => (v as num).toInt()),
        liveHosts: $checkedConvert('live_hosts', (v) => (v as num).toInt()),
        suspended: $checkedConvert('suspended', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'liveHosts': 'live_hosts'});

Map<String, dynamic> _$AdminDomainsCountsToJson(AdminDomainsCounts instance) =>
    <String, dynamic>{
      'connected': instance.connected,
      'registered': instance.registered,
      'live_hosts': instance.liveHosts,
      'suspended': instance.suspended,
    };
