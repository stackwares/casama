// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_resolved_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretResolvedEventPayloadCWProxy {
  SecretResolvedEventPayload requestId(String requestId);

  SecretResolvedEventPayload outcome(
    SecretResolvedEventPayloadOutcomeEnum outcome,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  SecretResolvedEventPayload call({
    String requestId,
    SecretResolvedEventPayloadOutcomeEnum outcome,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecretResolvedEventPayload.copyWith(...)` or call `instanceOfSecretResolvedEventPayload.copyWith.fieldName(value)` for a single field.
class _$SecretResolvedEventPayloadCWProxyImpl
    implements _$SecretResolvedEventPayloadCWProxy {
  const _$SecretResolvedEventPayloadCWProxyImpl(this._value);

  final SecretResolvedEventPayload _value;

  @override
  SecretResolvedEventPayload requestId(String requestId) =>
      call(requestId: requestId);

  @override
  SecretResolvedEventPayload outcome(
    SecretResolvedEventPayloadOutcomeEnum outcome,
  ) => call(outcome: outcome);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SecretResolvedEventPayload call({
    Object? requestId = const $CopyWithPlaceholder(),
    Object? outcome = const $CopyWithPlaceholder(),
  }) {
    return SecretResolvedEventPayload(
      requestId: requestId == const $CopyWithPlaceholder() || requestId == null
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
      outcome: outcome == const $CopyWithPlaceholder() || outcome == null
          ? _value.outcome
          // ignore: cast_nullable_to_non_nullable
          : outcome as SecretResolvedEventPayloadOutcomeEnum,
    );
  }
}

extension $SecretResolvedEventPayloadCopyWith on SecretResolvedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecretResolvedEventPayload.copyWith(...)` or `instanceOfSecretResolvedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretResolvedEventPayloadCWProxy get copyWith =>
      _$SecretResolvedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretResolvedEventPayload _$SecretResolvedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SecretResolvedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['request_id', 'outcome']);
  final val = SecretResolvedEventPayload(
    requestId: $checkedConvert('request_id', (v) => v as String),
    outcome: $checkedConvert(
      'outcome',
      (v) => $enumDecode(_$SecretResolvedEventPayloadOutcomeEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'requestId': 'request_id'});

Map<String, dynamic> _$SecretResolvedEventPayloadToJson(
  SecretResolvedEventPayload instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'outcome': _$SecretResolvedEventPayloadOutcomeEnumEnumMap[instance.outcome]!,
};

const _$SecretResolvedEventPayloadOutcomeEnumEnumMap = {
  SecretResolvedEventPayloadOutcomeEnum.fulfilled: 'fulfilled',
  SecretResolvedEventPayloadOutcomeEnum.declined: 'declined',
  SecretResolvedEventPayloadOutcomeEnum.expired: 'expired',
};
