// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_requested_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverRequestedEventPayloadCWProxy {
  TakeoverRequestedEventPayload computerId(String computerId);

  TakeoverRequestedEventPayload reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeoverRequestedEventPayload call({String computerId, String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeoverRequestedEventPayload.copyWith(...)` or call `instanceOfTakeoverRequestedEventPayload.copyWith.fieldName(value)` for a single field.
class _$TakeoverRequestedEventPayloadCWProxyImpl
    implements _$TakeoverRequestedEventPayloadCWProxy {
  const _$TakeoverRequestedEventPayloadCWProxyImpl(this._value);

  final TakeoverRequestedEventPayload _value;

  @override
  TakeoverRequestedEventPayload computerId(String computerId) =>
      call(computerId: computerId);

  @override
  TakeoverRequestedEventPayload reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeoverRequestedEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return TakeoverRequestedEventPayload(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $TakeoverRequestedEventPayloadCopyWith
    on TakeoverRequestedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeoverRequestedEventPayload.copyWith(...)` or `instanceOfTakeoverRequestedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverRequestedEventPayloadCWProxy get copyWith =>
      _$TakeoverRequestedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverRequestedEventPayload _$TakeoverRequestedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TakeoverRequestedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['computer_id', 'reason']);
  final val = TakeoverRequestedEventPayload(
    computerId: $checkedConvert('computer_id', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'computerId': 'computer_id'});

Map<String, dynamic> _$TakeoverRequestedEventPayloadToJson(
  TakeoverRequestedEventPayload instance,
) => <String, dynamic>{
  'computer_id': instance.computerId,
  'reason': instance.reason,
};
