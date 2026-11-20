// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_watcher_gate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesWatcherGateCWProxy {
  DecisionSettingsUsesWatcherGate mode(
    DecisionSettingsUsesWatcherGateModeEnum mode,
  );

  DecisionSettingsUsesWatcherGate skipBelow(num skipBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesWatcherGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesWatcherGate(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesWatcherGate call({
    DecisionSettingsUsesWatcherGateModeEnum mode,
    num skipBelow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesWatcherGate.copyWith(...)` or call `instanceOfDecisionSettingsUsesWatcherGate.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesWatcherGateCWProxyImpl
    implements _$DecisionSettingsUsesWatcherGateCWProxy {
  const _$DecisionSettingsUsesWatcherGateCWProxyImpl(this._value);

  final DecisionSettingsUsesWatcherGate _value;

  @override
  DecisionSettingsUsesWatcherGate mode(
    DecisionSettingsUsesWatcherGateModeEnum mode,
  ) => call(mode: mode);

  @override
  DecisionSettingsUsesWatcherGate skipBelow(num skipBelow) =>
      call(skipBelow: skipBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesWatcherGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesWatcherGate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesWatcherGate call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? skipBelow = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesWatcherGate(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesWatcherGateModeEnum,
      skipBelow: skipBelow == const $CopyWithPlaceholder() || skipBelow == null
          ? _value.skipBelow
          // ignore: cast_nullable_to_non_nullable
          : skipBelow as num,
    );
  }
}

extension $DecisionSettingsUsesWatcherGateCopyWith
    on DecisionSettingsUsesWatcherGate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesWatcherGate.copyWith(...)` or `instanceOfDecisionSettingsUsesWatcherGate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesWatcherGateCWProxy get copyWith =>
      _$DecisionSettingsUsesWatcherGateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesWatcherGate _$DecisionSettingsUsesWatcherGateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DecisionSettingsUsesWatcherGate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mode', 'skip_below']);
  final val = DecisionSettingsUsesWatcherGate(
    mode: $checkedConvert(
      'mode',
      (v) => $enumDecode(_$DecisionSettingsUsesWatcherGateModeEnumEnumMap, v),
    ),
    skipBelow: $checkedConvert('skip_below', (v) => v as num),
  );
  return val;
}, fieldKeyMap: const {'skipBelow': 'skip_below'});

Map<String, dynamic> _$DecisionSettingsUsesWatcherGateToJson(
  DecisionSettingsUsesWatcherGate instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesWatcherGateModeEnumEnumMap[instance.mode]!,
  'skip_below': instance.skipBelow,
};

const _$DecisionSettingsUsesWatcherGateModeEnumEnumMap = {
  DecisionSettingsUsesWatcherGateModeEnum.off: 'off',
  DecisionSettingsUsesWatcherGateModeEnum.shadow: 'shadow',
  DecisionSettingsUsesWatcherGateModeEnum.on_: 'on',
};
