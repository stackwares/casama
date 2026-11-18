// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_mcp_sign_in_needed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalMcpSignInNeededEventPayloadCWProxy {
  LocalMcpSignInNeededEventPayload integrationId(String integrationId);

  LocalMcpSignInNeededEventPayload deviceId(String deviceId);

  LocalMcpSignInNeededEventPayload server(String server);

  LocalMcpSignInNeededEventPayload label(String label);

  LocalMcpSignInNeededEventPayload botId(String botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpSignInNeededEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpSignInNeededEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalMcpSignInNeededEventPayload call({
    String integrationId,
    String deviceId,
    String server,
    String label,
    String botId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalMcpSignInNeededEventPayload.copyWith(...)` or call `instanceOfLocalMcpSignInNeededEventPayload.copyWith.fieldName(value)` for a single field.
class _$LocalMcpSignInNeededEventPayloadCWProxyImpl
    implements _$LocalMcpSignInNeededEventPayloadCWProxy {
  const _$LocalMcpSignInNeededEventPayloadCWProxyImpl(this._value);

  final LocalMcpSignInNeededEventPayload _value;

  @override
  LocalMcpSignInNeededEventPayload integrationId(String integrationId) =>
      call(integrationId: integrationId);

  @override
  LocalMcpSignInNeededEventPayload deviceId(String deviceId) =>
      call(deviceId: deviceId);

  @override
  LocalMcpSignInNeededEventPayload server(String server) =>
      call(server: server);

  @override
  LocalMcpSignInNeededEventPayload label(String label) => call(label: label);

  @override
  LocalMcpSignInNeededEventPayload botId(String botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpSignInNeededEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpSignInNeededEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalMcpSignInNeededEventPayload call({
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? deviceId = const $CopyWithPlaceholder(),
    Object? server = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return LocalMcpSignInNeededEventPayload(
      integrationId:
          integrationId == const $CopyWithPlaceholder() || integrationId == null
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String,
      deviceId: deviceId == const $CopyWithPlaceholder() || deviceId == null
          ? _value.deviceId
          // ignore: cast_nullable_to_non_nullable
          : deviceId as String,
      server: server == const $CopyWithPlaceholder() || server == null
          ? _value.server
          // ignore: cast_nullable_to_non_nullable
          : server as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
    );
  }
}

extension $LocalMcpSignInNeededEventPayloadCopyWith
    on LocalMcpSignInNeededEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalMcpSignInNeededEventPayload.copyWith(...)` or `instanceOfLocalMcpSignInNeededEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalMcpSignInNeededEventPayloadCWProxy get copyWith =>
      _$LocalMcpSignInNeededEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalMcpSignInNeededEventPayload _$LocalMcpSignInNeededEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'LocalMcpSignInNeededEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'integration_id',
        'device_id',
        'server',
        'label',
        'bot_id',
      ],
    );
    final val = LocalMcpSignInNeededEventPayload(
      integrationId: $checkedConvert('integration_id', (v) => v as String),
      deviceId: $checkedConvert('device_id', (v) => v as String),
      server: $checkedConvert('server', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'integrationId': 'integration_id',
    'deviceId': 'device_id',
    'botId': 'bot_id',
  },
);

Map<String, dynamic> _$LocalMcpSignInNeededEventPayloadToJson(
  LocalMcpSignInNeededEventPayload instance,
) => <String, dynamic>{
  'integration_id': instance.integrationId,
  'device_id': instance.deviceId,
  'server': instance.server,
  'label': instance.label,
  'bot_id': instance.botId,
};
