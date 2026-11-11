// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_session.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StreamSessionCWProxy {
  StreamSession signalingUrl(String signalingUrl);

  StreamSession token(String token);

  StreamSession mode(StreamMode mode);

  StreamSession expiresAt(DateTime expiresAt);

  StreamSession iceServers(List<IceServer> iceServers);

  StreamSession iceTransportPolicy(
    StreamSessionIceTransportPolicyEnum iceTransportPolicy,
  );

  StreamSession screenshotUrl(String screenshotUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StreamSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StreamSession(...).copyWith(id: 12, name: "My name")
  /// ```
  StreamSession call({
    String signalingUrl,
    String token,
    StreamMode mode,
    DateTime expiresAt,
    List<IceServer> iceServers,
    StreamSessionIceTransportPolicyEnum iceTransportPolicy,
    String screenshotUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStreamSession.copyWith(...)` or call `instanceOfStreamSession.copyWith.fieldName(value)` for a single field.
class _$StreamSessionCWProxyImpl implements _$StreamSessionCWProxy {
  const _$StreamSessionCWProxyImpl(this._value);

  final StreamSession _value;

  @override
  StreamSession signalingUrl(String signalingUrl) =>
      call(signalingUrl: signalingUrl);

  @override
  StreamSession token(String token) => call(token: token);

  @override
  StreamSession mode(StreamMode mode) => call(mode: mode);

  @override
  StreamSession expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  StreamSession iceServers(List<IceServer> iceServers) =>
      call(iceServers: iceServers);

  @override
  StreamSession iceTransportPolicy(
    StreamSessionIceTransportPolicyEnum iceTransportPolicy,
  ) => call(iceTransportPolicy: iceTransportPolicy);

  @override
  StreamSession screenshotUrl(String screenshotUrl) =>
      call(screenshotUrl: screenshotUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StreamSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StreamSession(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StreamSession call({
    Object? signalingUrl = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? iceServers = const $CopyWithPlaceholder(),
    Object? iceTransportPolicy = const $CopyWithPlaceholder(),
    Object? screenshotUrl = const $CopyWithPlaceholder(),
  }) {
    return StreamSession(
      signalingUrl:
          signalingUrl == const $CopyWithPlaceholder() || signalingUrl == null
          ? _value.signalingUrl
          // ignore: cast_nullable_to_non_nullable
          : signalingUrl as String,
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as StreamMode,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      iceServers:
          iceServers == const $CopyWithPlaceholder() || iceServers == null
          ? _value.iceServers
          // ignore: cast_nullable_to_non_nullable
          : iceServers as List<IceServer>,
      iceTransportPolicy:
          iceTransportPolicy == const $CopyWithPlaceholder() ||
              iceTransportPolicy == null
          ? _value.iceTransportPolicy
          // ignore: cast_nullable_to_non_nullable
          : iceTransportPolicy as StreamSessionIceTransportPolicyEnum,
      screenshotUrl:
          screenshotUrl == const $CopyWithPlaceholder() || screenshotUrl == null
          ? _value.screenshotUrl
          // ignore: cast_nullable_to_non_nullable
          : screenshotUrl as String,
    );
  }
}

extension $StreamSessionCopyWith on StreamSession {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStreamSession.copyWith(...)` or `instanceOfStreamSession.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StreamSessionCWProxy get copyWith => _$StreamSessionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreamSession _$StreamSessionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StreamSession',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'signaling_url',
            'token',
            'mode',
            'expires_at',
            'ice_servers',
            'ice_transport_policy',
            'screenshot_url',
          ],
        );
        final val = StreamSession(
          signalingUrl: $checkedConvert('signaling_url', (v) => v as String),
          token: $checkedConvert('token', (v) => v as String),
          mode: $checkedConvert(
            'mode',
            (v) => $enumDecode(_$StreamModeEnumMap, v),
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          iceServers: $checkedConvert(
            'ice_servers',
            (v) => (v as List<dynamic>)
                .map((e) => IceServer.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          iceTransportPolicy: $checkedConvert(
            'ice_transport_policy',
            (v) => $enumDecode(_$StreamSessionIceTransportPolicyEnumEnumMap, v),
          ),
          screenshotUrl: $checkedConvert('screenshot_url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'signalingUrl': 'signaling_url',
        'expiresAt': 'expires_at',
        'iceServers': 'ice_servers',
        'iceTransportPolicy': 'ice_transport_policy',
        'screenshotUrl': 'screenshot_url',
      },
    );

Map<String, dynamic> _$StreamSessionToJson(StreamSession instance) =>
    <String, dynamic>{
      'signaling_url': instance.signalingUrl,
      'token': instance.token,
      'mode': _$StreamModeEnumMap[instance.mode]!,
      'expires_at': instance.expiresAt.toIso8601String(),
      'ice_servers': instance.iceServers.map((e) => e.toJson()).toList(),
      'ice_transport_policy':
          _$StreamSessionIceTransportPolicyEnumEnumMap[instance
              .iceTransportPolicy]!,
      'screenshot_url': instance.screenshotUrl,
    };

const _$StreamModeEnumMap = {
  StreamMode.view: 'view',
  StreamMode.control: 'control',
};

const _$StreamSessionIceTransportPolicyEnumEnumMap = {
  StreamSessionIceTransportPolicyEnum.all: 'all',
  StreamSessionIceTransportPolicyEnum.relay: 'relay',
};
