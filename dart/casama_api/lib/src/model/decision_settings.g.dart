// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSettingsCWProxy {
  DecisionSettings model(String model);

  DecisionSettings shadowModels(List<String> shadowModels);

  DecisionSettings timeoutMs(int timeoutMs);

  DecisionSettings uses(DecisionSettingsUses uses);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSettings call({
    String model,
    List<String> shadowModels,
    int timeoutMs,
    DecisionSettingsUses uses,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSettings.copyWith(...)` or call `instanceOfDecisionSettings.copyWith.fieldName(value)` for a single field.
class _$DecisionSettingsCWProxyImpl implements _$DecisionSettingsCWProxy {
  const _$DecisionSettingsCWProxyImpl(this._value);

  final DecisionSettings _value;

  @override
  DecisionSettings model(String model) => call(model: model);

  @override
  DecisionSettings shadowModels(List<String> shadowModels) =>
      call(shadowModels: shadowModels);

  @override
  DecisionSettings timeoutMs(int timeoutMs) => call(timeoutMs: timeoutMs);

  @override
  DecisionSettings uses(DecisionSettingsUses uses) => call(uses: uses);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSettings call({
    Object? model = const $CopyWithPlaceholder(),
    Object? shadowModels = const $CopyWithPlaceholder(),
    Object? timeoutMs = const $CopyWithPlaceholder(),
    Object? uses = const $CopyWithPlaceholder(),
  }) {
    return DecisionSettings(
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      shadowModels:
          shadowModels == const $CopyWithPlaceholder() || shadowModels == null
          ? _value.shadowModels
          // ignore: cast_nullable_to_non_nullable
          : shadowModels as List<String>,
      timeoutMs: timeoutMs == const $CopyWithPlaceholder() || timeoutMs == null
          ? _value.timeoutMs
          // ignore: cast_nullable_to_non_nullable
          : timeoutMs as int,
      uses: uses == const $CopyWithPlaceholder() || uses == null
          ? _value.uses
          // ignore: cast_nullable_to_non_nullable
          : uses as DecisionSettingsUses,
    );
  }
}

extension $DecisionSettingsCopyWith on DecisionSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSettings.copyWith(...)` or `instanceOfDecisionSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSettingsCWProxy get copyWith => _$DecisionSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSettings _$DecisionSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DecisionSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['model', 'shadow_models', 'timeout_ms', 'uses'],
        );
        final val = DecisionSettings(
          model: $checkedConvert('model', (v) => v as String),
          shadowModels: $checkedConvert(
            'shadow_models',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          timeoutMs: $checkedConvert('timeout_ms', (v) => (v as num).toInt()),
          uses: $checkedConvert(
            'uses',
            (v) => DecisionSettingsUses.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'shadowModels': 'shadow_models',
        'timeoutMs': 'timeout_ms',
      },
    );

Map<String, dynamic> _$DecisionSettingsToJson(DecisionSettings instance) =>
    <String, dynamic>{
      'model': instance.model,
      'shadow_models': instance.shadowModels,
      'timeout_ms': instance.timeoutMs,
      'uses': instance.uses.toJson(),
    };
