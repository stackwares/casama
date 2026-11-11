// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_resolved_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverResolvedEventPayloadCWProxy {
  TakeoverResolvedEventPayload computerId(String computerId);

  TakeoverResolvedEventPayload outcome(
    TakeoverResolvedEventPayloadOutcomeEnum outcome,
  );

  TakeoverResolvedEventPayload note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeoverResolvedEventPayload call({
    String computerId,
    TakeoverResolvedEventPayloadOutcomeEnum outcome,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeoverResolvedEventPayload.copyWith(...)` or call `instanceOfTakeoverResolvedEventPayload.copyWith.fieldName(value)` for a single field.
class _$TakeoverResolvedEventPayloadCWProxyImpl
    implements _$TakeoverResolvedEventPayloadCWProxy {
  const _$TakeoverResolvedEventPayloadCWProxyImpl(this._value);

  final TakeoverResolvedEventPayload _value;

  @override
  TakeoverResolvedEventPayload computerId(String computerId) =>
      call(computerId: computerId);

  @override
  TakeoverResolvedEventPayload outcome(
    TakeoverResolvedEventPayloadOutcomeEnum outcome,
  ) => call(outcome: outcome);

  @override
  TakeoverResolvedEventPayload note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeoverResolvedEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? outcome = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return TakeoverResolvedEventPayload(
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      outcome: outcome == const $CopyWithPlaceholder() || outcome == null
          ? _value.outcome
          // ignore: cast_nullable_to_non_nullable
          : outcome as TakeoverResolvedEventPayloadOutcomeEnum,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $TakeoverResolvedEventPayloadCopyWith
    on TakeoverResolvedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeoverResolvedEventPayload.copyWith(...)` or `instanceOfTakeoverResolvedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverResolvedEventPayloadCWProxy get copyWith =>
      _$TakeoverResolvedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverResolvedEventPayload _$TakeoverResolvedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TakeoverResolvedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['computer_id', 'outcome', 'note']);
  final val = TakeoverResolvedEventPayload(
    computerId: $checkedConvert('computer_id', (v) => v as String),
    outcome: $checkedConvert(
      'outcome',
      (v) => $enumDecode(_$TakeoverResolvedEventPayloadOutcomeEnumEnumMap, v),
    ),
    note: $checkedConvert('note', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'computerId': 'computer_id'});

Map<String, dynamic> _$TakeoverResolvedEventPayloadToJson(
  TakeoverResolvedEventPayload instance,
) => <String, dynamic>{
  'computer_id': instance.computerId,
  'outcome':
      _$TakeoverResolvedEventPayloadOutcomeEnumEnumMap[instance.outcome]!,
  'note': instance.note,
};

const _$TakeoverResolvedEventPayloadOutcomeEnumEnumMap = {
  TakeoverResolvedEventPayloadOutcomeEnum.completed: 'completed',
  TakeoverResolvedEventPayloadOutcomeEnum.dismissed: 'dismissed',
  TakeoverResolvedEventPayloadOutcomeEnum.expired: 'expired',
};
