// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_requested_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretRequestedEventPayloadCWProxy {
  SecretRequestedEventPayload requestId(String requestId);

  SecretRequestedEventPayload name(String name);

  SecretRequestedEventPayload service(String service);

  SecretRequestedEventPayload allowedHosts(List<String> allowedHosts);

  SecretRequestedEventPayload reason(String reason);

  SecretRequestedEventPayload expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  SecretRequestedEventPayload call({
    String requestId,
    String name,
    String service,
    List<String> allowedHosts,
    String reason,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecretRequestedEventPayload.copyWith(...)` or call `instanceOfSecretRequestedEventPayload.copyWith.fieldName(value)` for a single field.
class _$SecretRequestedEventPayloadCWProxyImpl
    implements _$SecretRequestedEventPayloadCWProxy {
  const _$SecretRequestedEventPayloadCWProxyImpl(this._value);

  final SecretRequestedEventPayload _value;

  @override
  SecretRequestedEventPayload requestId(String requestId) =>
      call(requestId: requestId);

  @override
  SecretRequestedEventPayload name(String name) => call(name: name);

  @override
  SecretRequestedEventPayload service(String service) => call(service: service);

  @override
  SecretRequestedEventPayload allowedHosts(List<String> allowedHosts) =>
      call(allowedHosts: allowedHosts);

  @override
  SecretRequestedEventPayload reason(String reason) => call(reason: reason);

  @override
  SecretRequestedEventPayload expiresAt(DateTime expiresAt) =>
      call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SecretRequestedEventPayload call({
    Object? requestId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? service = const $CopyWithPlaceholder(),
    Object? allowedHosts = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return SecretRequestedEventPayload(
      requestId: requestId == const $CopyWithPlaceholder() || requestId == null
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      service: service == const $CopyWithPlaceholder() || service == null
          ? _value.service
          // ignore: cast_nullable_to_non_nullable
          : service as String,
      allowedHosts:
          allowedHosts == const $CopyWithPlaceholder() || allowedHosts == null
          ? _value.allowedHosts
          // ignore: cast_nullable_to_non_nullable
          : allowedHosts as List<String>,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $SecretRequestedEventPayloadCopyWith on SecretRequestedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecretRequestedEventPayload.copyWith(...)` or `instanceOfSecretRequestedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretRequestedEventPayloadCWProxy get copyWith =>
      _$SecretRequestedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretRequestedEventPayload _$SecretRequestedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SecretRequestedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'request_id',
        'name',
        'service',
        'allowed_hosts',
        'reason',
        'expires_at',
      ],
    );
    final val = SecretRequestedEventPayload(
      requestId: $checkedConvert('request_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      service: $checkedConvert('service', (v) => v as String),
      allowedHosts: $checkedConvert(
        'allowed_hosts',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      reason: $checkedConvert('reason', (v) => v as String),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'requestId': 'request_id',
    'allowedHosts': 'allowed_hosts',
    'expiresAt': 'expires_at',
  },
);

Map<String, dynamic> _$SecretRequestedEventPayloadToJson(
  SecretRequestedEventPayload instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'name': instance.name,
  'service': instance.service,
  'allowed_hosts': instance.allowedHosts,
  'reason': instance.reason,
  'expires_at': instance.expiresAt.toIso8601String(),
};
