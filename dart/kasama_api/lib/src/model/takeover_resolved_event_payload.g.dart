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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverResolvedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverResolvedEventPayload call({
    String computerId,
    TakeoverResolvedEventPayloadOutcomeEnum outcome,
    String? note,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTakeoverResolvedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTakeoverResolvedEventPayload.copyWith.fieldName(...)`
class _$TakeoverResolvedEventPayloadCWProxyImpl
    implements _$TakeoverResolvedEventPayloadCWProxy {
  const _$TakeoverResolvedEventPayloadCWProxyImpl(this._value);

  final TakeoverResolvedEventPayload _value;

  @override
  TakeoverResolvedEventPayload computerId(String computerId) =>
      this(computerId: computerId);

  @override
  TakeoverResolvedEventPayload outcome(
    TakeoverResolvedEventPayloadOutcomeEnum outcome,
  ) => this(outcome: outcome);

  @override
  TakeoverResolvedEventPayload note(String? note) => this(note: note);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverResolvedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverResolvedEventPayload call({
    Object? computerId = const $CopyWithPlaceholder(),
    Object? outcome = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return TakeoverResolvedEventPayload(
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      outcome: outcome == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfTakeoverResolvedEventPayload.copyWith(...)` or like so:`instanceOfTakeoverResolvedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverResolvedEventPayloadCWProxy get copyWith =>
      _$TakeoverResolvedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverResolvedEventPayload _$TakeoverResolvedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TakeoverResolvedEventPayload',
  json,
  ($checkedConvert) {
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
  },
  fieldKeyMap: const {'computerId': 'computer_id'},
);

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
