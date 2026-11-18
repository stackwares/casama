// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_run.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceRunCWProxy {
  GlanceRun id(String id);

  GlanceRun botId(String botId);

  GlanceRun bot(String bot);

  GlanceRun botAvatar(String botAvatar);

  GlanceRun phase(GlanceRunPhaseEnum phase);

  GlanceRun step(String step);

  GlanceRun steps(int steps);

  GlanceRun startedAt(DateTime startedAt);

  GlanceRun approvalId(String? approvalId);

  GlanceRun risk(GlanceRunRiskEnum? risk);

  GlanceRun link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceRun(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceRun call({
    String id,
    String botId,
    String bot,
    String botAvatar,
    GlanceRunPhaseEnum phase,
    String step,
    int steps,
    DateTime startedAt,
    String? approvalId,
    GlanceRunRiskEnum? risk,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceRun.copyWith(...)` or call `instanceOfGlanceRun.copyWith.fieldName(value)` for a single field.
class _$GlanceRunCWProxyImpl implements _$GlanceRunCWProxy {
  const _$GlanceRunCWProxyImpl(this._value);

  final GlanceRun _value;

  @override
  GlanceRun id(String id) => call(id: id);

  @override
  GlanceRun botId(String botId) => call(botId: botId);

  @override
  GlanceRun bot(String bot) => call(bot: bot);

  @override
  GlanceRun botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  GlanceRun phase(GlanceRunPhaseEnum phase) => call(phase: phase);

  @override
  GlanceRun step(String step) => call(step: step);

  @override
  GlanceRun steps(int steps) => call(steps: steps);

  @override
  GlanceRun startedAt(DateTime startedAt) => call(startedAt: startedAt);

  @override
  GlanceRun approvalId(String? approvalId) => call(approvalId: approvalId);

  @override
  GlanceRun risk(GlanceRunRiskEnum? risk) => call(risk: risk);

  @override
  GlanceRun link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceRun(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceRun call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? phase = const $CopyWithPlaceholder(),
    Object? step = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? approvalId = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return GlanceRun(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      bot: bot == const $CopyWithPlaceholder() || bot == null
          ? _value.bot
          // ignore: cast_nullable_to_non_nullable
          : bot as String,
      botAvatar: botAvatar == const $CopyWithPlaceholder() || botAvatar == null
          ? _value.botAvatar
          // ignore: cast_nullable_to_non_nullable
          : botAvatar as String,
      phase: phase == const $CopyWithPlaceholder() || phase == null
          ? _value.phase
          // ignore: cast_nullable_to_non_nullable
          : phase as GlanceRunPhaseEnum,
      step: step == const $CopyWithPlaceholder() || step == null
          ? _value.step
          // ignore: cast_nullable_to_non_nullable
          : step as String,
      steps: steps == const $CopyWithPlaceholder() || steps == null
          ? _value.steps
          // ignore: cast_nullable_to_non_nullable
          : steps as int,
      startedAt: startedAt == const $CopyWithPlaceholder() || startedAt == null
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime,
      approvalId: approvalId == const $CopyWithPlaceholder()
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String?,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as GlanceRunRiskEnum?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $GlanceRunCopyWith on GlanceRun {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceRun.copyWith(...)` or `instanceOfGlanceRun.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceRunCWProxy get copyWith => _$GlanceRunCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceRun _$GlanceRunFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GlanceRun',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'bot',
        'bot_avatar',
        'phase',
        'step',
        'steps',
        'started_at',
        'approval_id',
        'risk',
        'link',
      ],
    );
    final val = GlanceRun(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      bot: $checkedConvert('bot', (v) => v as String),
      botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
      phase: $checkedConvert(
        'phase',
        (v) => $enumDecode(_$GlanceRunPhaseEnumEnumMap, v),
      ),
      step: $checkedConvert('step', (v) => v as String),
      steps: $checkedConvert('steps', (v) => (v as num).toInt()),
      startedAt: $checkedConvert(
        'started_at',
        (v) => DateTime.parse(v as String),
      ),
      approvalId: $checkedConvert('approval_id', (v) => v as String?),
      risk: $checkedConvert(
        'risk',
        (v) => $enumDecodeNullable(_$GlanceRunRiskEnumEnumMap, v),
      ),
      link: $checkedConvert('link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'botAvatar': 'bot_avatar',
    'startedAt': 'started_at',
    'approvalId': 'approval_id',
  },
);

Map<String, dynamic> _$GlanceRunToJson(GlanceRun instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'bot': instance.bot,
  'bot_avatar': instance.botAvatar,
  'phase': _$GlanceRunPhaseEnumEnumMap[instance.phase]!,
  'step': instance.step,
  'steps': instance.steps,
  'started_at': instance.startedAt.toIso8601String(),
  'approval_id': instance.approvalId,
  'risk': _$GlanceRunRiskEnumEnumMap[instance.risk],
  'link': instance.link,
};

const _$GlanceRunPhaseEnumEnumMap = {
  GlanceRunPhaseEnum.working: 'working',
  GlanceRunPhaseEnum.needsOk: 'needs_ok',
  GlanceRunPhaseEnum.takeOver: 'take_over',
};

const _$GlanceRunRiskEnumEnumMap = {
  GlanceRunRiskEnum.low: 'low',
  GlanceRunRiskEnum.medium: 'medium',
  GlanceRunRiskEnum.high: 'high',
};
