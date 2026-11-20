// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_tool_gate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesToolGateCWProxy {
  DecisionSettingsUsesToolGate mode(DecisionSettingsUsesToolGateModeEnum mode);

  DecisionSettingsUsesToolGate askBelow(num askBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesToolGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesToolGate(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesToolGate call({
    DecisionSettingsUsesToolGateModeEnum mode,
    num askBelow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesToolGate.copyWith(...)` or call `instanceOfDecisionSettingsUsesToolGate.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesToolGateCWProxyImpl
    implements _$DecisionSettingsUsesToolGateCWProxy {
  const _$DecisionSettingsUsesToolGateCWProxyImpl(this._value);

  final DecisionSettingsUsesToolGate _value;

  @override
  DecisionSettingsUsesToolGate mode(
    DecisionSettingsUsesToolGateModeEnum mode,
  ) => call(mode: mode);

  @override
  DecisionSettingsUsesToolGate askBelow(num askBelow) =>
      call(askBelow: askBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesToolGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesToolGate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesToolGate call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? askBelow = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesToolGate(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesToolGateModeEnum,
      askBelow: askBelow == const $CopyWithPlaceholder() || askBelow == null
          ? _value.askBelow
          // ignore: cast_nullable_to_non_nullable
          : askBelow as num,
    );
  }
}

extension $DecisionSettingsUsesToolGateCopyWith
    on DecisionSettingsUsesToolGate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesToolGate.copyWith(...)` or `instanceOfDecisionSettingsUsesToolGate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesToolGateCWProxy get copyWith =>
      _$DecisionSettingsUsesToolGateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesToolGate _$DecisionSettingsUsesToolGateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DecisionSettingsUsesToolGate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mode', 'ask_below']);
  final val = DecisionSettingsUsesToolGate(
    mode: $checkedConvert(
      'mode',
      (v) => $enumDecode(_$DecisionSettingsUsesToolGateModeEnumEnumMap, v),
    ),
    askBelow: $checkedConvert('ask_below', (v) => v as num),
  );
  return val;
}, fieldKeyMap: const {'askBelow': 'ask_below'});

Map<String, dynamic> _$DecisionSettingsUsesToolGateToJson(
  DecisionSettingsUsesToolGate instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesToolGateModeEnumEnumMap[instance.mode]!,
  'ask_below': instance.askBelow,
};

const _$DecisionSettingsUsesToolGateModeEnumEnumMap = {
  DecisionSettingsUsesToolGateModeEnum.off: 'off',
  DecisionSettingsUsesToolGateModeEnum.shadow: 'shadow',
  DecisionSettingsUsesToolGateModeEnum.on_: 'on',
};
