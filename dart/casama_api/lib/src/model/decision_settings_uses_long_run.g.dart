// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_long_run.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesLongRunCWProxy {
  DecisionSettingsUsesLongRun mode(DecisionSettingsUsesLongRunModeEnum mode);

  DecisionSettingsUsesLongRun repeatingAbove(num repeatingAbove);

  DecisionSettingsUsesLongRun firstStep(int firstStep);

  DecisionSettingsUsesLongRun every(int every);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesLongRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesLongRun(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesLongRun call({
    DecisionSettingsUsesLongRunModeEnum mode,
    num repeatingAbove,
    int firstStep,
    int every,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesLongRun.copyWith(...)` or call `instanceOfDecisionSettingsUsesLongRun.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesLongRunCWProxyImpl
    implements _$DecisionSettingsUsesLongRunCWProxy {
  const _$DecisionSettingsUsesLongRunCWProxyImpl(this._value);

  final DecisionSettingsUsesLongRun _value;

  @override
  DecisionSettingsUsesLongRun mode(DecisionSettingsUsesLongRunModeEnum mode) =>
      call(mode: mode);

  @override
  DecisionSettingsUsesLongRun repeatingAbove(num repeatingAbove) =>
      call(repeatingAbove: repeatingAbove);

  @override
  DecisionSettingsUsesLongRun firstStep(int firstStep) =>
      call(firstStep: firstStep);

  @override
  DecisionSettingsUsesLongRun every(int every) => call(every: every);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesLongRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesLongRun(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesLongRun call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? repeatingAbove = const $CopyWithPlaceholder(),
    Object? firstStep = const $CopyWithPlaceholder(),
    Object? every = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesLongRun(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesLongRunModeEnum,
      repeatingAbove:
          repeatingAbove == const $CopyWithPlaceholder() ||
              repeatingAbove == null
          ? _value.repeatingAbove
          // ignore: cast_nullable_to_non_nullable
          : repeatingAbove as num,
      firstStep: firstStep == const $CopyWithPlaceholder() || firstStep == null
          ? _value.firstStep
          // ignore: cast_nullable_to_non_nullable
          : firstStep as int,
      every: every == const $CopyWithPlaceholder() || every == null
          ? _value.every
          // ignore: cast_nullable_to_non_nullable
          : every as int,
    );
  }
}

extension $DecisionSettingsUsesLongRunCopyWith on DecisionSettingsUsesLongRun {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesLongRun.copyWith(...)` or `instanceOfDecisionSettingsUsesLongRun.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesLongRunCWProxy get copyWith =>
      _$DecisionSettingsUsesLongRunCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesLongRun _$DecisionSettingsUsesLongRunFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DecisionSettingsUsesLongRun',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['mode', 'repeating_above', 'first_step', 'every'],
    );
    final val = DecisionSettingsUsesLongRun(
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$DecisionSettingsUsesLongRunModeEnumEnumMap, v),
      ),
      repeatingAbove: $checkedConvert('repeating_above', (v) => v as num),
      firstStep: $checkedConvert('first_step', (v) => (v as num).toInt()),
      every: $checkedConvert('every', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'repeatingAbove': 'repeating_above',
    'firstStep': 'first_step',
  },
);

Map<String, dynamic> _$DecisionSettingsUsesLongRunToJson(
  DecisionSettingsUsesLongRun instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesLongRunModeEnumEnumMap[instance.mode]!,
  'repeating_above': instance.repeatingAbove,
  'first_step': instance.firstStep,
  'every': instance.every,
};

const _$DecisionSettingsUsesLongRunModeEnumEnumMap = {
  DecisionSettingsUsesLongRunModeEnum.off: 'off',
  DecisionSettingsUsesLongRunModeEnum.shadow: 'shadow',
  DecisionSettingsUsesLongRunModeEnum.on_: 'on',
};
