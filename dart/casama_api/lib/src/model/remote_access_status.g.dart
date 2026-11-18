// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_access_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemoteAccessStatusCWProxy {
  RemoteAccessStatus state(String state);

  RemoteAccessStatus address(String? address);

  RemoteAccessStatus pagesAddress(String? pagesAddress);

  RemoteAccessStatus localAddress(String? localAddress);

  RemoteAccessStatus linked(bool linked);

  RemoteAccessStatus problem(String? problem);

  RemoteAccessStatus connections(int? connections);

  RemoteAccessStatus checkedAt(DateTime? checkedAt);

  RemoteAccessStatus push(String? push);

  RemoteAccessStatus privateNotifications(bool? privateNotifications);

  RemoteAccessStatus invites(bool? invites);

  RemoteAccessStatus liveView(String? liveView);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAccessStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAccessStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  RemoteAccessStatus call({
    String state,
    String? address,
    String? pagesAddress,
    String? localAddress,
    bool linked,
    String? problem,
    int? connections,
    DateTime? checkedAt,
    String? push,
    bool? privateNotifications,
    bool? invites,
    String? liveView,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemoteAccessStatus.copyWith(...)` or call `instanceOfRemoteAccessStatus.copyWith.fieldName(value)` for a single field.
class _$RemoteAccessStatusCWProxyImpl implements _$RemoteAccessStatusCWProxy {
  const _$RemoteAccessStatusCWProxyImpl(this._value);

  final RemoteAccessStatus _value;

  @override
  RemoteAccessStatus state(String state) => call(state: state);

  @override
  RemoteAccessStatus address(String? address) => call(address: address);

  @override
  RemoteAccessStatus pagesAddress(String? pagesAddress) =>
      call(pagesAddress: pagesAddress);

  @override
  RemoteAccessStatus localAddress(String? localAddress) =>
      call(localAddress: localAddress);

  @override
  RemoteAccessStatus linked(bool linked) => call(linked: linked);

  @override
  RemoteAccessStatus problem(String? problem) => call(problem: problem);

  @override
  RemoteAccessStatus connections(int? connections) =>
      call(connections: connections);

  @override
  RemoteAccessStatus checkedAt(DateTime? checkedAt) =>
      call(checkedAt: checkedAt);

  @override
  RemoteAccessStatus push(String? push) => call(push: push);

  @override
  RemoteAccessStatus privateNotifications(bool? privateNotifications) =>
      call(privateNotifications: privateNotifications);

  @override
  RemoteAccessStatus invites(bool? invites) => call(invites: invites);

  @override
  RemoteAccessStatus liveView(String? liveView) => call(liveView: liveView);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAccessStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAccessStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemoteAccessStatus call({
    Object? state = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? pagesAddress = const $CopyWithPlaceholder(),
    Object? localAddress = const $CopyWithPlaceholder(),
    Object? linked = const $CopyWithPlaceholder(),
    Object? problem = const $CopyWithPlaceholder(),
    Object? connections = const $CopyWithPlaceholder(),
    Object? checkedAt = const $CopyWithPlaceholder(),
    Object? push = const $CopyWithPlaceholder(),
    Object? privateNotifications = const $CopyWithPlaceholder(),
    Object? invites = const $CopyWithPlaceholder(),
    Object? liveView = const $CopyWithPlaceholder(),
  }) {
    return RemoteAccessStatus(
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as String,
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String?,
      pagesAddress: pagesAddress == const $CopyWithPlaceholder()
          ? _value.pagesAddress
          // ignore: cast_nullable_to_non_nullable
          : pagesAddress as String?,
      localAddress: localAddress == const $CopyWithPlaceholder()
          ? _value.localAddress
          // ignore: cast_nullable_to_non_nullable
          : localAddress as String?,
      linked: linked == const $CopyWithPlaceholder() || linked == null
          ? _value.linked
          // ignore: cast_nullable_to_non_nullable
          : linked as bool,
      problem: problem == const $CopyWithPlaceholder()
          ? _value.problem
          // ignore: cast_nullable_to_non_nullable
          : problem as String?,
      connections: connections == const $CopyWithPlaceholder()
          ? _value.connections
          // ignore: cast_nullable_to_non_nullable
          : connections as int?,
      checkedAt: checkedAt == const $CopyWithPlaceholder()
          ? _value.checkedAt
          // ignore: cast_nullable_to_non_nullable
          : checkedAt as DateTime?,
      push: push == const $CopyWithPlaceholder()
          ? _value.push
          // ignore: cast_nullable_to_non_nullable
          : push as String?,
      privateNotifications: privateNotifications == const $CopyWithPlaceholder()
          ? _value.privateNotifications
          // ignore: cast_nullable_to_non_nullable
          : privateNotifications as bool?,
      invites: invites == const $CopyWithPlaceholder()
          ? _value.invites
          // ignore: cast_nullable_to_non_nullable
          : invites as bool?,
      liveView: liveView == const $CopyWithPlaceholder()
          ? _value.liveView
          // ignore: cast_nullable_to_non_nullable
          : liveView as String?,
    );
  }
}

extension $RemoteAccessStatusCopyWith on RemoteAccessStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemoteAccessStatus.copyWith(...)` or `instanceOfRemoteAccessStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemoteAccessStatusCWProxy get copyWith =>
      _$RemoteAccessStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAccessStatus _$RemoteAccessStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RemoteAccessStatus',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'state',
            'address',
            'pages_address',
            'local_address',
            'linked',
            'problem',
            'connections',
            'checked_at',
          ],
        );
        final val = RemoteAccessStatus(
          state: $checkedConvert('state', (v) => v as String),
          address: $checkedConvert('address', (v) => v as String?),
          pagesAddress: $checkedConvert('pages_address', (v) => v as String?),
          localAddress: $checkedConvert('local_address', (v) => v as String?),
          linked: $checkedConvert('linked', (v) => v as bool),
          problem: $checkedConvert('problem', (v) => v as String?),
          connections: $checkedConvert(
            'connections',
            (v) => (v as num?)?.toInt(),
          ),
          checkedAt: $checkedConvert(
            'checked_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          push: $checkedConvert('push', (v) => v as String?),
          privateNotifications: $checkedConvert(
            'private_notifications',
            (v) => v as bool?,
          ),
          invites: $checkedConvert('invites', (v) => v as bool?),
          liveView: $checkedConvert('live_view', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'pagesAddress': 'pages_address',
        'localAddress': 'local_address',
        'checkedAt': 'checked_at',
        'privateNotifications': 'private_notifications',
        'liveView': 'live_view',
      },
    );

Map<String, dynamic> _$RemoteAccessStatusToJson(RemoteAccessStatus instance) =>
    <String, dynamic>{
      'state': instance.state,
      'address': instance.address,
      'pages_address': instance.pagesAddress,
      'local_address': instance.localAddress,
      'linked': instance.linked,
      'problem': instance.problem,
      'connections': instance.connections,
      'checked_at': instance.checkedAt?.toIso8601String(),
      'push': ?instance.push,
      'private_notifications': ?instance.privateNotifications,
      'invites': ?instance.invites,
      'live_view': ?instance.liveView,
    };
