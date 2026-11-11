// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbound_call.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OutboundCallCWProxy {
  OutboundCall id(String id);

  OutboundCall botId(String botId);

  OutboundCall number(String number);

  OutboundCall purpose(String purpose);

  OutboundCall status(OutboundCallStatusEnum status);

  OutboundCall transcript(List<OutboundCallTranscriptInner> transcript);

  OutboundCall seconds(int? seconds);

  OutboundCall startedAt(DateTime? startedAt);

  OutboundCall endedAt(DateTime? endedAt);

  OutboundCall createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OutboundCall(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OutboundCall(...).copyWith(id: 12, name: "My name")
  /// ```
  OutboundCall call({
    String id,
    String botId,
    String number,
    String purpose,
    OutboundCallStatusEnum status,
    List<OutboundCallTranscriptInner> transcript,
    int? seconds,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOutboundCall.copyWith(...)` or call `instanceOfOutboundCall.copyWith.fieldName(value)` for a single field.
class _$OutboundCallCWProxyImpl implements _$OutboundCallCWProxy {
  const _$OutboundCallCWProxyImpl(this._value);

  final OutboundCall _value;

  @override
  OutboundCall id(String id) => call(id: id);

  @override
  OutboundCall botId(String botId) => call(botId: botId);

  @override
  OutboundCall number(String number) => call(number: number);

  @override
  OutboundCall purpose(String purpose) => call(purpose: purpose);

  @override
  OutboundCall status(OutboundCallStatusEnum status) => call(status: status);

  @override
  OutboundCall transcript(List<OutboundCallTranscriptInner> transcript) =>
      call(transcript: transcript);

  @override
  OutboundCall seconds(int? seconds) => call(seconds: seconds);

  @override
  OutboundCall startedAt(DateTime? startedAt) => call(startedAt: startedAt);

  @override
  OutboundCall endedAt(DateTime? endedAt) => call(endedAt: endedAt);

  @override
  OutboundCall createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OutboundCall(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OutboundCall(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OutboundCall call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? number = const $CopyWithPlaceholder(),
    Object? purpose = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? transcript = const $CopyWithPlaceholder(),
    Object? seconds = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? endedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return OutboundCall(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      number: number == const $CopyWithPlaceholder() || number == null
          ? _value.number
          // ignore: cast_nullable_to_non_nullable
          : number as String,
      purpose: purpose == const $CopyWithPlaceholder() || purpose == null
          ? _value.purpose
          // ignore: cast_nullable_to_non_nullable
          : purpose as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as OutboundCallStatusEnum,
      transcript:
          transcript == const $CopyWithPlaceholder() || transcript == null
          ? _value.transcript
          // ignore: cast_nullable_to_non_nullable
          : transcript as List<OutboundCallTranscriptInner>,
      seconds: seconds == const $CopyWithPlaceholder()
          ? _value.seconds
          // ignore: cast_nullable_to_non_nullable
          : seconds as int?,
      startedAt: startedAt == const $CopyWithPlaceholder()
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime?,
      endedAt: endedAt == const $CopyWithPlaceholder()
          ? _value.endedAt
          // ignore: cast_nullable_to_non_nullable
          : endedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $OutboundCallCopyWith on OutboundCall {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOutboundCall.copyWith(...)` or `instanceOfOutboundCall.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OutboundCallCWProxy get copyWith => _$OutboundCallCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutboundCall _$OutboundCallFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OutboundCall',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'bot_id',
            'number',
            'purpose',
            'status',
            'transcript',
            'seconds',
            'started_at',
            'ended_at',
            'created_at',
          ],
        );
        final val = OutboundCall(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          number: $checkedConvert('number', (v) => v as String),
          purpose: $checkedConvert('purpose', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$OutboundCallStatusEnumEnumMap, v),
          ),
          transcript: $checkedConvert(
            'transcript',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => OutboundCallTranscriptInner.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
          seconds: $checkedConvert('seconds', (v) => (v as num?)?.toInt()),
          startedAt: $checkedConvert(
            'started_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          endedAt: $checkedConvert(
            'ended_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'botId': 'bot_id',
        'startedAt': 'started_at',
        'endedAt': 'ended_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$OutboundCallToJson(OutboundCall instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'number': instance.number,
      'purpose': instance.purpose,
      'status': _$OutboundCallStatusEnumEnumMap[instance.status]!,
      'transcript': instance.transcript.map((e) => e.toJson()).toList(),
      'seconds': instance.seconds,
      'started_at': instance.startedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$OutboundCallStatusEnumEnumMap = {
  OutboundCallStatusEnum.queued: 'queued',
  OutboundCallStatusEnum.ringing: 'ringing',
  OutboundCallStatusEnum.inProgress: 'in_progress',
  OutboundCallStatusEnum.completed: 'completed',
  OutboundCallStatusEnum.failed: 'failed',
  OutboundCallStatusEnum.busy: 'busy',
  OutboundCallStatusEnum.noAnswer: 'no_answer',
  OutboundCallStatusEnum.endedByUser: 'ended_by_user',
  OutboundCallStatusEnum.takenOver: 'taken_over',
};
