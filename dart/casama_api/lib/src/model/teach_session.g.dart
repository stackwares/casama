// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teach_session.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachSessionCWProxy {
  TeachSession id(String id);

  TeachSession botId(String botId);

  TeachSession computerId(String computerId);

  TeachSession status(TeachSessionStatusEnum status);

  TeachSession conversationId(String? conversationId);

  TeachSession draft(TeachDraft? draft);

  TeachSession skillId(String? skillId);

  TeachSession steps(List<TeachStep> steps);

  TeachSession startedAt(DateTime startedAt);

  TeachSession stoppedAt(DateTime? stoppedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachSession(...).copyWith(id: 12, name: "My name")
  /// ```
  TeachSession call({
    String id,
    String botId,
    String computerId,
    TeachSessionStatusEnum status,
    String? conversationId,
    TeachDraft? draft,
    String? skillId,
    List<TeachStep> steps,
    DateTime startedAt,
    DateTime? stoppedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeachSession.copyWith(...)` or call `instanceOfTeachSession.copyWith.fieldName(value)` for a single field.
class _$TeachSessionCWProxyImpl implements _$TeachSessionCWProxy {
  const _$TeachSessionCWProxyImpl(this._value);

  final TeachSession _value;

  @override
  TeachSession id(String id) => call(id: id);

  @override
  TeachSession botId(String botId) => call(botId: botId);

  @override
  TeachSession computerId(String computerId) => call(computerId: computerId);

  @override
  TeachSession status(TeachSessionStatusEnum status) => call(status: status);

  @override
  TeachSession conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  TeachSession draft(TeachDraft? draft) => call(draft: draft);

  @override
  TeachSession skillId(String? skillId) => call(skillId: skillId);

  @override
  TeachSession steps(List<TeachStep> steps) => call(steps: steps);

  @override
  TeachSession startedAt(DateTime startedAt) => call(startedAt: startedAt);

  @override
  TeachSession stoppedAt(DateTime? stoppedAt) => call(stoppedAt: stoppedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachSession(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachSession(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TeachSession call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? draft = const $CopyWithPlaceholder(),
    Object? skillId = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? stoppedAt = const $CopyWithPlaceholder(),
  }) {
    return TeachSession(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TeachSessionStatusEnum,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      draft: draft == const $CopyWithPlaceholder()
          ? _value.draft
          // ignore: cast_nullable_to_non_nullable
          : draft as TeachDraft?,
      skillId: skillId == const $CopyWithPlaceholder()
          ? _value.skillId
          // ignore: cast_nullable_to_non_nullable
          : skillId as String?,
      steps: steps == const $CopyWithPlaceholder() || steps == null
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as List<TeachStep>,
      startedAt: startedAt == const $CopyWithPlaceholder() || startedAt == null
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime,
      stoppedAt: stoppedAt == const $CopyWithPlaceholder()
          ? _value.stoppedAt
          // ignore: cast_nullable_to_non_nullable
          : stoppedAt as DateTime?,
    );
  }
}

extension $TeachSessionCopyWith on TeachSession {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeachSession.copyWith(...)` or `instanceOfTeachSession.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachSessionCWProxy get copyWith => _$TeachSessionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachSession _$TeachSessionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TeachSession',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'computer_id',
        'status',
        'conversation_id',
        'draft',
        'skill_id',
        'steps',
        'started_at',
        'stopped_at',
      ],
    );
    final val = TeachSession(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      computerId: $checkedConvert('computer_id', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TeachSessionStatusEnumEnumMap, v),
      ),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      draft: $checkedConvert(
        'draft',
        (v) =>
            v == null ? null : TeachDraft.fromJson(v as Map<String, dynamic>),
      ),
      skillId: $checkedConvert('skill_id', (v) => v as String?),
      steps: $checkedConvert(
        'steps',
        (v) => (v as List<dynamic>)
            .map((e) => TeachStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      startedAt: $checkedConvert(
        'started_at',
        (v) => DateTime.parse(v as String),
      ),
      stoppedAt: $checkedConvert(
        'stopped_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'computerId': 'computer_id',
    'conversationId': 'conversation_id',
    'skillId': 'skill_id',
    'startedAt': 'started_at',
    'stoppedAt': 'stopped_at',
  },
);

Map<String, dynamic> _$TeachSessionToJson(TeachSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'computer_id': instance.computerId,
      'status': _$TeachSessionStatusEnumEnumMap[instance.status]!,
      'conversation_id': instance.conversationId,
      'draft': instance.draft?.toJson(),
      'skill_id': instance.skillId,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'started_at': instance.startedAt.toIso8601String(),
      'stopped_at': instance.stoppedAt?.toIso8601String(),
    };

const _$TeachSessionStatusEnumEnumMap = {
  TeachSessionStatusEnum.recording: 'recording',
  TeachSessionStatusEnum.drafting: 'drafting',
  TeachSessionStatusEnum.drafted: 'drafted',
  TeachSessionStatusEnum.saved: 'saved',
  TeachSessionStatusEnum.cancelled: 'cancelled',
  TeachSessionStatusEnum.failed: 'failed',
};
