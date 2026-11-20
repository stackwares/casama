// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_push_score.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesPushScoreCWProxy {
  DecisionSettingsUsesPushScore mode(
    DecisionSettingsUsesPushScoreModeEnum mode,
  );

  DecisionSettingsUsesPushScore holdBelow(num holdBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesPushScore(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesPushScore(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesPushScore call({
    DecisionSettingsUsesPushScoreModeEnum mode,
    num holdBelow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesPushScore.copyWith(...)` or call `instanceOfDecisionSettingsUsesPushScore.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesPushScoreCWProxyImpl
    implements _$DecisionSettingsUsesPushScoreCWProxy {
  const _$DecisionSettingsUsesPushScoreCWProxyImpl(this._value);

  final DecisionSettingsUsesPushScore _value;

  @override
  DecisionSettingsUsesPushScore mode(
    DecisionSettingsUsesPushScoreModeEnum mode,
  ) => call(mode: mode);

  @override
  DecisionSettingsUsesPushScore holdBelow(num holdBelow) =>
      call(holdBelow: holdBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesPushScore(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesPushScore(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesPushScore call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? holdBelow = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesPushScore(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesPushScoreModeEnum,
      holdBelow: holdBelow == const $CopyWithPlaceholder() || holdBelow == null
          ? _value.holdBelow
          // ignore: cast_nullable_to_non_nullable
          : holdBelow as num,
    );
  }
}

extension $DecisionSettingsUsesPushScoreCopyWith
    on DecisionSettingsUsesPushScore {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesPushScore.copyWith(...)` or `instanceOfDecisionSettingsUsesPushScore.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesPushScoreCWProxy get copyWith =>
      _$DecisionSettingsUsesPushScoreCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesPushScore _$DecisionSettingsUsesPushScoreFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DecisionSettingsUsesPushScore', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mode', 'hold_below']);
  final val = DecisionSettingsUsesPushScore(
    mode: $checkedConvert(
      'mode',
      (v) => $enumDecode(_$DecisionSettingsUsesPushScoreModeEnumEnumMap, v),
    ),
    holdBelow: $checkedConvert('hold_below', (v) => v as num),
  );
  return val;
}, fieldKeyMap: const {'holdBelow': 'hold_below'});

Map<String, dynamic> _$DecisionSettingsUsesPushScoreToJson(
  DecisionSettingsUsesPushScore instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesPushScoreModeEnumEnumMap[instance.mode]!,
  'hold_below': instance.holdBelow,
};

const _$DecisionSettingsUsesPushScoreModeEnumEnumMap = {
  DecisionSettingsUsesPushScoreModeEnum.off: 'off',
  DecisionSettingsUsesPushScoreModeEnum.shadow: 'shadow',
  DecisionSettingsUsesPushScoreModeEnum.on_: 'on',
};
