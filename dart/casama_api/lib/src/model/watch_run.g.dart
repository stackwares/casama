// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_run.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchRunCWProxy {
  WatchRun id(String id);

  WatchRun botId(String botId);

  WatchRun bot(String bot);

  WatchRun botAvatar(String botAvatar);

  WatchRun conversationId(String? conversationId);

  WatchRun phase(WatchRunPhaseEnum phase);

  WatchRun step(String step);

  WatchRun steps(int steps);

  WatchRun startedAt(DateTime startedAt);

  WatchRun endedAt(DateTime? endedAt);

  WatchRun approval(WatchApproval? approval);

  WatchRun reply(WatchMessage? reply);

  WatchRun link(String link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchRun(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchRun call({
    String id,
    String botId,
    String bot,
    String botAvatar,
    String? conversationId,
    WatchRunPhaseEnum phase,
    String step,
    int steps,
    DateTime startedAt,
    DateTime? endedAt,
    WatchApproval? approval,
    WatchMessage? reply,
    String link,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchRun.copyWith(...)` or call `instanceOfWatchRun.copyWith.fieldName(value)` for a single field.
class _$WatchRunCWProxyImpl implements _$WatchRunCWProxy {
  const _$WatchRunCWProxyImpl(this._value);

  final WatchRun _value;

  @override
  WatchRun id(String id) => call(id: id);

  @override
  WatchRun botId(String botId) => call(botId: botId);

  @override
  WatchRun bot(String bot) => call(bot: bot);

  @override
  WatchRun botAvatar(String botAvatar) => call(botAvatar: botAvatar);

  @override
  WatchRun conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  WatchRun phase(WatchRunPhaseEnum phase) => call(phase: phase);

  @override
  WatchRun step(String step) => call(step: step);

  @override
  WatchRun steps(int steps) => call(steps: steps);

  @override
  WatchRun startedAt(DateTime startedAt) => call(startedAt: startedAt);

  @override
  WatchRun endedAt(DateTime? endedAt) => call(endedAt: endedAt);

  @override
  WatchRun approval(WatchApproval? approval) => call(approval: approval);

  @override
  WatchRun reply(WatchMessage? reply) => call(reply: reply);

  @override
  WatchRun link(String link) => call(link: link);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchRun(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchRun call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? bot = const $CopyWithPlaceholder(),
    Object? botAvatar = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? phase = const $CopyWithPlaceholder(),
    Object? step = const $CopyWithPlaceholder(),
    Object? steps = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? endedAt = const $CopyWithPlaceholder(),
    Object? approval = const $CopyWithPlaceholder(),
    Object? reply = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
  }) {
    return WatchRun(
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
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      phase: phase == const $CopyWithPlaceholder() || phase == null
          ? _value.phase
          // ignore: cast_nullable_to_non_nullable
          : phase as WatchRunPhaseEnum,
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
      endedAt: endedAt == const $CopyWithPlaceholder()
          ? _value.endedAt
          // ignore: cast_nullable_to_non_nullable
          : endedAt as DateTime?,
      approval: approval == const $CopyWithPlaceholder()
          ? _value.approval
          // ignore: cast_nullable_to_non_nullable
          : approval as WatchApproval?,
      reply: reply == const $CopyWithPlaceholder()
          ? _value.reply
          // ignore: cast_nullable_to_non_nullable
          : reply as WatchMessage?,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
    );
  }
}

extension $WatchRunCopyWith on WatchRun {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchRun.copyWith(...)` or `instanceOfWatchRun.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchRunCWProxy get copyWith => _$WatchRunCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchRun _$WatchRunFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchRun',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'bot',
        'bot_avatar',
        'conversation_id',
        'phase',
        'step',
        'steps',
        'started_at',
        'ended_at',
        'approval',
        'reply',
        'link',
      ],
    );
    final val = WatchRun(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      bot: $checkedConvert('bot', (v) => v as String),
      botAvatar: $checkedConvert('bot_avatar', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      phase: $checkedConvert(
        'phase',
        (v) => $enumDecode(_$WatchRunPhaseEnumEnumMap, v),
      ),
      step: $checkedConvert('step', (v) => v as String),
      steps: $checkedConvert('steps', (v) => (v as num).toInt()),
      startedAt: $checkedConvert(
        'started_at',
        (v) => DateTime.parse(v as String),
      ),
      endedAt: $checkedConvert(
        'ended_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      approval: $checkedConvert(
        'approval',
        (v) => v == null
            ? null
            : WatchApproval.fromJson(v as Map<String, dynamic>),
      ),
      reply: $checkedConvert(
        'reply',
        (v) =>
            v == null ? null : WatchMessage.fromJson(v as Map<String, dynamic>),
      ),
      link: $checkedConvert('link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'botAvatar': 'bot_avatar',
    'conversationId': 'conversation_id',
    'startedAt': 'started_at',
    'endedAt': 'ended_at',
  },
);

Map<String, dynamic> _$WatchRunToJson(WatchRun instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'bot': instance.bot,
  'bot_avatar': instance.botAvatar,
  'conversation_id': instance.conversationId,
  'phase': _$WatchRunPhaseEnumEnumMap[instance.phase]!,
  'step': instance.step,
  'steps': instance.steps,
  'started_at': instance.startedAt.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'approval': instance.approval?.toJson(),
  'reply': instance.reply?.toJson(),
  'link': instance.link,
};

const _$WatchRunPhaseEnumEnumMap = {
  WatchRunPhaseEnum.working: 'working',
  WatchRunPhaseEnum.needsOk: 'needs_ok',
  WatchRunPhaseEnum.takeOver: 'take_over',
  WatchRunPhaseEnum.finished: 'finished',
  WatchRunPhaseEnum.problem: 'problem',
  WatchRunPhaseEnum.stopped: 'stopped',
};
