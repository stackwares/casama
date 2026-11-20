// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings_uses_scan_gate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsUsesScanGateCWProxy {
  DecisionSettingsUsesScanGate mode(DecisionSettingsUsesScanGateModeEnum mode);

  DecisionSettingsUsesScanGate skipBelow(num skipBelow);

  DecisionSettingsUsesScanGate maxSkipsInRow(int maxSkipsInRow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesScanGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesScanGate(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettingsUsesScanGate call({
    DecisionSettingsUsesScanGateModeEnum mode,
    num skipBelow,
    int maxSkipsInRow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettingsUsesScanGate.copyWith(...)` or call `instanceOfDecisionSettingsUsesScanGate.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsUsesScanGateCWProxyImpl
    implements _$DecisionSettingsUsesScanGateCWProxy {
  const _$DecisionSettingsUsesScanGateCWProxyImpl(this._value);

  final DecisionSettingsUsesScanGate _value;

  @override
  DecisionSettingsUsesScanGate mode(
    DecisionSettingsUsesScanGateModeEnum mode,
  ) => call(mode: mode);

  @override
  DecisionSettingsUsesScanGate skipBelow(num skipBelow) =>
      call(skipBelow: skipBelow);

  @override
  DecisionSettingsUsesScanGate maxSkipsInRow(int maxSkipsInRow) =>
      call(maxSkipsInRow: maxSkipsInRow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettingsUsesScanGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettingsUsesScanGate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettingsUsesScanGate call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? skipBelow = const $CopyWithPlaceholder(),
    Object? maxSkipsInRow = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettingsUsesScanGate(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as DecisionSettingsUsesScanGateModeEnum,
      skipBelow: skipBelow == const $CopyWithPlaceholder() || skipBelow == null
          ? _value.skipBelow
          // ignore: cast_nullable_to_non_nullable
          : skipBelow as num,
      maxSkipsInRow:
          maxSkipsInRow == const $CopyWithPlaceholder() || maxSkipsInRow == null
          ? _value.maxSkipsInRow
          // ignore: cast_nullable_to_non_nullable
          : maxSkipsInRow as int,
    );
  }
}

extension $DecisionSettingsUsesScanGateCopyWith
    on DecisionSettingsUsesScanGate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettingsUsesScanGate.copyWith(...)` or `instanceOfDecisionSettingsUsesScanGate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsUsesScanGateCWProxy get copyWith =>
      _$DecisionSettingsUsesScanGateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettingsUsesScanGate _$DecisionSettingsUsesScanGateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DecisionSettingsUsesScanGate',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['mode', 'skip_below', 'max_skips_in_row'],
    );
    final val = DecisionSettingsUsesScanGate(
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$DecisionSettingsUsesScanGateModeEnumEnumMap, v),
      ),
      skipBelow: $checkedConvert('skip_below', (v) => v as num),
      maxSkipsInRow: $checkedConvert(
        'max_skips_in_row',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'skipBelow': 'skip_below',
    'maxSkipsInRow': 'max_skips_in_row',
  },
);

Map<String, dynamic> _$DecisionSettingsUsesScanGateToJson(
  DecisionSettingsUsesScanGate instance,
) => <String, dynamic>{
  'mode': _$DecisionSettingsUsesScanGateModeEnumEnumMap[instance.mode]!,
  'skip_below': instance.skipBelow,
  'max_skips_in_row': instance.maxSkipsInRow,
};

const _$DecisionSettingsUsesScanGateModeEnumEnumMap = {
  DecisionSettingsUsesScanGateModeEnum.off: 'off',
  DecisionSettingsUsesScanGateModeEnum.shadow: 'shadow',
  DecisionSettingsUsesScanGateModeEnum.on_: 'on',
};
