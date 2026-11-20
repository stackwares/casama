// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesCWProxy {
  DecisionSettingsUses scanGate(DecisionSettingsUsesScanGate scanGate);

  DecisionSettingsUses replyCheck(DecisionSettingsUsesReplyCheck replyCheck);

  DecisionSettingsUses pushScore(DecisionSettingsUsesPushScore pushScore);

  DecisionSettingsUses toolGate(DecisionSettingsUsesToolGate toolGate);

  DecisionSettingsUses longRun(DecisionSettingsUsesLongRun longRun);

  DecisionSettingsUses effort(DecisionSettingsUsesEffort effort);

  DecisionSettingsUses watcherGate(DecisionSettingsUsesWatcherGate watcherGate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUses(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUses(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUses call({
    DecisionSettingsUsesScanGate scanGate,
    DecisionSettingsUsesReplyCheck replyCheck,
    DecisionSettingsUsesPushScore pushScore,
    DecisionSettingsUsesToolGate toolGate,
    DecisionSettingsUsesLongRun longRun,
    DecisionSettingsUsesEffort effort,
    DecisionSettingsUsesWatcherGate watcherGate,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUses.copyWith(...)` or call `instanceOfDecisionSettingsUses.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesCWProxyImpl
    implements _$DecisionSettingsUsesCWProxy {
  const _$DecisionSettingsUsesCWProxyImpl(this._value);

  final DecisionSettingsUses _value;

  @override
  DecisionSettingsUses scanGate(DecisionSettingsUsesScanGate scanGate) =>
      call(scanGate: scanGate);

  @override
  DecisionSettingsUses replyCheck(DecisionSettingsUsesReplyCheck replyCheck) =>
      call(replyCheck: replyCheck);

  @override
  DecisionSettingsUses pushScore(DecisionSettingsUsesPushScore pushScore) =>
      call(pushScore: pushScore);

  @override
  DecisionSettingsUses toolGate(DecisionSettingsUsesToolGate toolGate) =>
      call(toolGate: toolGate);

  @override
  DecisionSettingsUses longRun(DecisionSettingsUsesLongRun longRun) =>
      call(longRun: longRun);

  @override
  DecisionSettingsUses effort(DecisionSettingsUsesEffort effort) =>
      call(effort: effort);

  @override
  DecisionSettingsUses watcherGate(
    DecisionSettingsUsesWatcherGate watcherGate,
  ) => call(watcherGate: watcherGate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUses(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUses(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUses call({
    Object? scanGate = const $CopyWithPlaceholder(),
    Object? replyCheck = const $CopyWithPlaceholder(),
    Object? pushScore = const $CopyWithPlaceholder(),
    Object? toolGate = const $CopyWithPlaceholder(),
    Object? longRun = const $CopyWithPlaceholder(),
    Object? effort = const $CopyWithPlaceholder(),
    Object? watcherGate = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUses(
      scanGate: scanGate == const $CopyWithPlaceholder() || scanGate == null
          ? _value.scanGate
          // ignore: cast_nullable_to_non_nullable
          : scanGate as DecisionSettingsUsesScanGate,
      replyCheck:
          replyCheck == const $CopyWithPlaceholder() || replyCheck == null
          ? _value.replyCheck
          // ignore: cast_nullable_to_non_nullable
          : replyCheck as DecisionSettingsUsesReplyCheck,
      pushScore: pushScore == const $CopyWithPlaceholder() || pushScore == null
          ? _value.pushScore
          // ignore: cast_nullable_to_non_nullable
          : pushScore as DecisionSettingsUsesPushScore,
      toolGate: toolGate == const $CopyWithPlaceholder() || toolGate == null
          ? _value.toolGate
          // ignore: cast_nullable_to_non_nullable
          : toolGate as DecisionSettingsUsesToolGate,
      longRun: longRun == const $CopyWithPlaceholder() || longRun == null
          ? _value.longRun
          // ignore: cast_nullable_to_non_nullable
          : longRun as DecisionSettingsUsesLongRun,
      effort: effort == const $CopyWithPlaceholder() || effort == null
          ? _value.effort
          // ignore: cast_nullable_to_non_nullable
          : effort as DecisionSettingsUsesEffort,
      watcherGate:
          watcherGate == const $CopyWithPlaceholder() || watcherGate == null
          ? _value.watcherGate
          // ignore: cast_nullable_to_non_nullable
          : watcherGate as DecisionSettingsUsesWatcherGate,
    );
  }
}

extension $DecisionSettingsUsesCopyWith on DecisionSettingsUses {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUses.copyWith(...)` or `instanceOfDecisionSettingsUses.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesCWProxy get copyWith =>
      _$DecisionSettingsUsesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUses _$DecisionSettingsUsesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DecisionSettingsUses',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'scan_gate',
        'reply_check',
        'push_score',
        'tool_gate',
        'long_run',
        'effort',
        'watcher_gate',
      ],
    );
    final val = DecisionSettingsUses(
      scanGate: $checkedConvert(
        'scan_gate',
        (v) => DecisionSettingsUsesScanGate.fromJson(v as Map<String, dynamic>),
      ),
      replyCheck: $checkedConvert(
        'reply_check',
        (v) =>
            DecisionSettingsUsesReplyCheck.fromJson(v as Map<String, dynamic>),
      ),
      pushScore: $checkedConvert(
        'push_score',
        (v) =>
            DecisionSettingsUsesPushScore.fromJson(v as Map<String, dynamic>),
      ),
      toolGate: $checkedConvert(
        'tool_gate',
        (v) => DecisionSettingsUsesToolGate.fromJson(v as Map<String, dynamic>),
      ),
      longRun: $checkedConvert(
        'long_run',
        (v) => DecisionSettingsUsesLongRun.fromJson(v as Map<String, dynamic>),
      ),
      effort: $checkedConvert(
        'effort',
        (v) => DecisionSettingsUsesEffort.fromJson(v as Map<String, dynamic>),
      ),
      watcherGate: $checkedConvert(
        'watcher_gate',
        (v) =>
            DecisionSettingsUsesWatcherGate.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'scanGate': 'scan_gate',
    'replyCheck': 'reply_check',
    'pushScore': 'push_score',
    'toolGate': 'tool_gate',
    'longRun': 'long_run',
    'watcherGate': 'watcher_gate',
  },
);

Map<String, dynamic> _$DecisionSettingsUsesToJson(
  DecisionSettingsUses instance,
) => <String, dynamic>{
  'scan_gate': instance.scanGate.toJson(),
  'reply_check': instance.replyCheck.toJson(),
  'push_score': instance.pushScore.toJson(),
  'tool_gate': instance.toolGate.toJson(),
  'long_run': instance.longRun.toJson(),
  'effort': instance.effort.toJson(),
  'watcher_gate': instance.watcherGate.toJson(),
};
