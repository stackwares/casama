// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_proposal.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillProposalCWProxy {
  SkillProposal id(String id);

  SkillProposal botId(String botId);

  SkillProposal kind(SkillProposalKindEnum kind);

  SkillProposal skillId(String? skillId);

  SkillProposal name(String name);

  SkillProposal description(String description);

  SkillProposal bodyMd(String bodyMd);

  SkillProposal previousBodyMd(String? previousBodyMd);

  SkillProposal tools(List<String> tools);

  SkillProposal reason(String reason);

  SkillProposal status(SkillProposalStatusEnum status);

  SkillProposal createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillProposal(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillProposal(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillProposal call({
    String id,
    String botId,
    SkillProposalKindEnum kind,
    String? skillId,
    String name,
    String description,
    String bodyMd,
    String? previousBodyMd,
    List<String> tools,
    String reason,
    SkillProposalStatusEnum status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillProposal.copyWith(...)` or call `instanceOfSkillProposal.copyWith.fieldName(value)` for a single field.
class _$SkillProposalCWProxyImpl implements _$SkillProposalCWProxy {
  const _$SkillProposalCWProxyImpl(this._value);

  final SkillProposal _value;

  @override
  SkillProposal id(String id) => call(id: id);

  @override
  SkillProposal botId(String botId) => call(botId: botId);

  @override
  SkillProposal kind(SkillProposalKindEnum kind) => call(kind: kind);

  @override
  SkillProposal skillId(String? skillId) => call(skillId: skillId);

  @override
  SkillProposal name(String name) => call(name: name);

  @override
  SkillProposal description(String description) =>
      call(description: description);

  @override
  SkillProposal bodyMd(String bodyMd) => call(bodyMd: bodyMd);

  @override
  SkillProposal previousBodyMd(String? previousBodyMd) =>
      call(previousBodyMd: previousBodyMd);

  @override
  SkillProposal tools(List<String> tools) => call(tools: tools);

  @override
  SkillProposal reason(String reason) => call(reason: reason);

  @override
  SkillProposal status(SkillProposalStatusEnum status) => call(status: status);

  @override
  SkillProposal createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillProposal(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillProposal(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillProposal call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? skillId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? bodyMd = const $CopyWithPlaceholder(),
    Object? previousBodyMd = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return SkillProposal(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as SkillProposalKindEnum,
      skillId: skillId == const $CopyWithPlaceholder()
          ? _value.skillId
          // ignore: cast_nullable_to_non_nullable
          : skillId as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      bodyMd: bodyMd == const $CopyWithPlaceholder() || bodyMd == null
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String,
      previousBodyMd: previousBodyMd == const $CopyWithPlaceholder()
          ? _value.previousBodyMd
          // ignore: cast_nullable_to_non_nullable
          : previousBodyMd as String?,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as List<String>,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SkillProposalStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SkillProposalCopyWith on SkillProposal {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillProposal.copyWith(...)` or `instanceOfSkillProposal.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillProposalCWProxy get copyWith => _$SkillProposalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillProposal _$SkillProposalFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SkillProposal',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'bot_id',
            'kind',
            'skill_id',
            'name',
            'description',
            'body_md',
            'previous_body_md',
            'tools',
            'reason',
            'status',
            'created_at',
          ],
        );
        final val = SkillProposal(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$SkillProposalKindEnumEnumMap, v),
          ),
          skillId: $checkedConvert('skill_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          bodyMd: $checkedConvert('body_md', (v) => v as String),
          previousBodyMd: $checkedConvert(
            'previous_body_md',
            (v) => v as String?,
          ),
          tools: $checkedConvert(
            'tools',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          reason: $checkedConvert('reason', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$SkillProposalStatusEnumEnumMap, v),
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
        'skillId': 'skill_id',
        'bodyMd': 'body_md',
        'previousBodyMd': 'previous_body_md',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$SkillProposalToJson(SkillProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'kind': _$SkillProposalKindEnumEnumMap[instance.kind]!,
      'skill_id': instance.skillId,
      'name': instance.name,
      'description': instance.description,
      'body_md': instance.bodyMd,
      'previous_body_md': instance.previousBodyMd,
      'tools': instance.tools,
      'reason': instance.reason,
      'status': _$SkillProposalStatusEnumEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$SkillProposalKindEnumEnumMap = {
  SkillProposalKindEnum.new_: 'new',
  SkillProposalKindEnum.edit: 'edit',
};

const _$SkillProposalStatusEnumEnumMap = {
  SkillProposalStatusEnum.pending: 'pending',
  SkillProposalStatusEnum.accepted: 'accepted',
  SkillProposalStatusEnum.dismissed: 'dismissed',
  SkillProposalStatusEnum.applied: 'applied',
};
