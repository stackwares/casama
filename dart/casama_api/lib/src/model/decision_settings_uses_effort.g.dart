// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_effort.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesEffortCWProxy {
  DecisionSettingsUsesEffort mode(DecisionSettingsUsesEffortModeEnum mode);

  DecisionSettingsUsesEffort quickAbove(num quickAbove);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesEffort(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesEffort(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesEffort call({
    DecisionSettingsUsesEffortModeEnum mode,
    num quickAbove,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesEffort.copyWith(...)` or call `instanceOfDecisionSettingsUsesEffort.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesEffortCWProxyImpl
    implements _$DecisionSettingsUsesEffortCWProxy {
  const _$DecisionSettingsUsesEffortCWProxyImpl(this._value);

  final DecisionSettingsUsesEffort _value;

  @override
  DecisionSettingsUsesEffort mode(DecisionSettingsUsesEffortModeEnum mode) =>
      call(mode: mode);

  @override
  DecisionSettingsUsesEffort quickAbove(num quickAbove) =>
      call(quickAbove: quickAbove);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesEffort(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesEffort(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesEffort call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? quickAbove = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesEffort(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesEffortModeEnum,
      quickAbove:
          quickAbove == const $CopyWithPlaceholder() || quickAbove == null
          ? _value.quickAbove
          // ignore: cast_nullable_to_non_nullable
          : quickAbove as num,
    );
  }
}

extension $DecisionSettingsUsesEffortCopyWith on DecisionSettingsUsesEffort {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesEffort.copyWith(...)` or `instanceOfDecisionSettingsUsesEffort.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesEffortCWProxy get copyWith =>
      _$DecisionSettingsUsesEffortCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesEffort _$DecisionSettingsUsesEffortFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DecisionSettingsUsesEffort', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mode', 'quick_above']);
  final val = DecisionSettingsUsesEffort(
    mode: $checkedConvert(
      'mode',
      (v) => $enumDecode(_$DecisionSettingsUsesEffortModeEnumEnumMap, v),
    ),
    quickAbove: $checkedConvert('quick_above', (v) => v as num),
  );
  return val;
}, fieldKeyMap: const {'quickAbove': 'quick_above'});

Map<String, dynamic> _$DecisionSettingsUsesEffortToJson(
  DecisionSettingsUsesEffort instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesEffortModeEnumEnumMap[instance.mode]!,
  'quick_above': instance.quickAbove,
};

const _$DecisionSettingsUsesEffortModeEnumEnumMap = {
  DecisionSettingsUsesEffortModeEnum.off: 'off',
  DecisionSettingsUsesEffortModeEnum.shadow: 'shadow',
  DecisionSettingsUsesEffortModeEnum.on_: 'on',
};
