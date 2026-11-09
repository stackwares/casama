// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_overview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminOverviewCWProxy {
  AdminOverview version(String version);

  AdminOverview users(int users);

  AdminOverview orgs(int orgs);

  AdminOverview bots(int bots);

  AdminOverview runs24h(int runs24h);

  AdminOverview failedRuns24h(int failedRuns24h);

  AdminOverview cost24hUsd(num cost24hUsd);

  AdminOverview computersRunning(int computersRunning);

  AdminOverview devicesOnline(int devicesOnline);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminOverview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminOverview(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminOverview call({
    String version,
    int users,
    int orgs,
    int bots,
    int runs24h,
    int failedRuns24h,
    num cost24hUsd,
    int computersRunning,
    int devicesOnline,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminOverview.copyWith(...)` or call `instanceOfAdminOverview.copyWith.fieldName(value)` for a single field.
class _$AdminOverviewCWProxyImpl implements _$AdminOverviewCWProxy {
  const _$AdminOverviewCWProxyImpl(this._value);

  final AdminOverview _value;

  @override
  AdminOverview version(String version) => call(version: version);

  @override
  AdminOverview users(int users) => call(users: users);

  @override
  AdminOverview orgs(int orgs) => call(orgs: orgs);

  @override
  AdminOverview bots(int bots) => call(bots: bots);

  @override
  AdminOverview runs24h(int runs24h) => call(runs24h: runs24h);

  @override
  AdminOverview failedRuns24h(int failedRuns24h) =>
      call(failedRuns24h: failedRuns24h);

  @override
  AdminOverview cost24hUsd(num cost24hUsd) => call(cost24hUsd: cost24hUsd);

  @override
  AdminOverview computersRunning(int computersRunning) =>
      call(computersRunning: computersRunning);

  @override
  AdminOverview devicesOnline(int devicesOnline) =>
      call(devicesOnline: devicesOnline);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminOverview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminOverview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminOverview call({
    Object? version = const $CopyWithPlaceholder(),
    Object? users = const $CopyWithPlaceholder(),
    Object? orgs = const $CopyWithPlaceholder(),
    Object? bots = const $CopyWithPlaceholder(),
    Object? runs24h = const $CopyWithPlaceholder(),
    Object? failedRuns24h = const $CopyWithPlaceholder(),
    Object? cost24hUsd = const $CopyWithPlaceholder(),
    Object? computersRunning = const $CopyWithPlaceholder(),
    Object? devicesOnline = const $CopyWithPlaceholder(),
  }) {
    return AdminOverview(
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      users: users == const $CopyWithPlaceholder() || users == null
          ? _value.users
          // ignore: cast_nullable_to_non_nullable
          : users as int,
      orgs: orgs == const $CopyWithPlaceholder() || orgs == null
          ? _value.orgs
          // ignore: cast_nullable_to_non_nullable
          : orgs as int,
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as int,
      runs24h: runs24h == const $CopyWithPlaceholder() || runs24h == null
          ? _value.runs24h
          // ignore: cast_nullable_to_non_nullable
          : runs24h as int,
      failedRuns24h:
          failedRuns24h == const $CopyWithPlaceholder() || failedRuns24h == null
          ? _value.failedRuns24h
          // ignore: cast_nullable_to_non_nullable
          : failedRuns24h as int,
      cost24hUsd:
          cost24hUsd == const $CopyWithPlaceholder() || cost24hUsd == null
          ? _value.cost24hUsd
          // ignore: cast_nullable_to_non_nullable
          : cost24hUsd as num,
      computersRunning:
          computersRunning == const $CopyWithPlaceholder() ||
              computersRunning == null
          ? _value.computersRunning
          // ignore: cast_nullable_to_non_nullable
          : computersRunning as int,
      devicesOnline:
          devicesOnline == const $CopyWithPlaceholder() || devicesOnline == null
          ? _value.devicesOnline
          // ignore: cast_nullable_to_non_nullable
          : devicesOnline as int,
    );
  }
}

extension $AdminOverviewCopyWith on AdminOverview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminOverview.copyWith(...)` or `instanceOfAdminOverview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminOverviewCWProxy get copyWith => _$AdminOverviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOverview _$AdminOverviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminOverview',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'version',
            'users',
            'orgs',
            'bots',
            'runs_24h',
            'failed_runs_24h',
            'cost_24h_usd',
            'computers_running',
            'devices_online',
          ],
        );
        final val = AdminOverview(
          version: $checkedConvert('version', (v) => v as String),
          users: $checkedConvert('users', (v) => (v as num).toInt()),
          orgs: $checkedConvert('orgs', (v) => (v as num).toInt()),
          bots: $checkedConvert('bots', (v) => (v as num).toInt()),
          runs24h: $checkedConvert('runs_24h', (v) => (v as num).toInt()),
          failedRuns24h: $checkedConvert(
            'failed_runs_24h',
            (v) => (v as num).toInt(),
          ),
          cost24hUsd: $checkedConvert('cost_24h_usd', (v) => v as num),
          computersRunning: $checkedConvert(
            'computers_running',
            (v) => (v as num).toInt(),
          ),
          devicesOnline: $checkedConvert(
            'devices_online',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'runs24h': 'runs_24h',
        'failedRuns24h': 'failed_runs_24h',
        'cost24hUsd': 'cost_24h_usd',
        'computersRunning': 'computers_running',
        'devicesOnline': 'devices_online',
      },
    );

Map<String, dynamic> _$AdminOverviewToJson(AdminOverview instance) =>
    <String, dynamic>{
      'version': instance.version,
      'users': instance.users,
      'orgs': instance.orgs,
      'bots': instance.bots,
      'runs_24h': instance.runs24h,
      'failed_runs_24h': instance.failedRuns24h,
      'cost_24h_usd': instance.cost24hUsd,
      'computers_running': instance.computersRunning,
      'devices_online': instance.devicesOnline,
    };
