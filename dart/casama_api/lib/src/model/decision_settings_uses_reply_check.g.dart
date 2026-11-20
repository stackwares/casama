// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_reply_check.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesReplyCheckCWProxy {
  DecisionSettingsUsesReplyCheck mode(
    DecisionSettingsUsesReplyCheckModeEnum mode,
  );

  DecisionSettingsUsesReplyCheck flagAbove(num flagAbove);

  DecisionSettingsUsesReplyCheck memorySkipBelow(num memorySkipBelow);

  DecisionSettingsUsesReplyCheck correctionAbove(num correctionAbove);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesReplyCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesReplyCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesReplyCheck call({
    DecisionSettingsUsesReplyCheckModeEnum mode,
    num flagAbove,
    num memorySkipBelow,
    num correctionAbove,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesReplyCheck.copyWith(...)` or call `instanceOfDecisionSettingsUsesReplyCheck.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesReplyCheckCWProxyImpl
    implements _$DecisionSettingsUsesReplyCheckCWProxy {
  const _$DecisionSettingsUsesReplyCheckCWProxyImpl(this._value);

  final DecisionSettingsUsesReplyCheck _value;

  @override
  DecisionSettingsUsesReplyCheck mode(
    DecisionSettingsUsesReplyCheckModeEnum mode,
  ) => call(mode: mode);

  @override
  DecisionSettingsUsesReplyCheck flagAbove(num flagAbove) =>
      call(flagAbove: flagAbove);

  @override
  DecisionSettingsUsesReplyCheck memorySkipBelow(num memorySkipBelow) =>
      call(memorySkipBelow: memorySkipBelow);

  @override
  DecisionSettingsUsesReplyCheck correctionAbove(num correctionAbove) =>
      call(correctionAbove: correctionAbove);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesReplyCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesReplyCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesReplyCheck call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? flagAbove = const $CopyWithPlaceholder(),
    Object? memorySkipBelow = const $CopyWithPlaceholder(),
    Object? correctionAbove = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesReplyCheck(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesReplyCheckModeEnum,
      flagAbove: flagAbove == const $CopyWithPlaceholder() || flagAbove == null
          ? _value.flagAbove
          // ignore: cast_nullable_to_non_nullable
          : flagAbove as num,
      memorySkipBelow:
          memorySkipBelow == const $CopyWithPlaceholder() ||
              memorySkipBelow == null
          ? _value.memorySkipBelow
          // ignore: cast_nullable_to_non_nullable
          : memorySkipBelow as num,
      correctionAbove:
          correctionAbove == const $CopyWithPlaceholder() ||
              correctionAbove == null
          ? _value.correctionAbove
          // ignore: cast_nullable_to_non_nullable
          : correctionAbove as num,
    );
  }
}

extension $DecisionSettingsUsesReplyCheckCopyWith
    on DecisionSettingsUsesReplyCheck {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesReplyCheck.copyWith(...)` or `instanceOfDecisionSettingsUsesReplyCheck.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesReplyCheckCWProxy get copyWith =>
      _$DecisionSettingsUsesReplyCheckCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesReplyCheck _$DecisionSettingsUsesReplyCheckFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DecisionSettingsUsesReplyCheck',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'mode',
        'flag_above',
        'memory_skip_below',
        'correction_above',
      ],
    );
    final val = DecisionSettingsUsesReplyCheck(
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$DecisionSettingsUsesReplyCheckModeEnumEnumMap, v),
      ),
      flagAbove: $checkedConvert('flag_above', (v) => v as num),
      memorySkipBelow: $checkedConvert('memory_skip_below', (v) => v as num),
      correctionAbove: $checkedConvert('correction_above', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'flagAbove': 'flag_above',
    'memorySkipBelow': 'memory_skip_below',
    'correctionAbove': 'correction_above',
  },
);

Map<String, dynamic> _$DecisionSettingsUsesReplyCheckToJson(
  DecisionSettingsUsesReplyCheck instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesReplyCheckModeEnumEnumMap[instance.mode]!,
  'flag_above': instance.flagAbove,
  'memory_skip_below': instance.memorySkipBelow,
  'correction_above': instance.correctionAbove,
};

const _$DecisionSettingsUsesReplyCheckModeEnumEnumMap = {
  DecisionSettingsUsesReplyCheckModeEnum.off: 'off',
  DecisionSettingsUsesReplyCheckModeEnum.shadow: 'shadow',
  DecisionSettingsUsesReplyCheckModeEnum.on_: 'on',
};
