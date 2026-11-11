// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_choice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelChoiceCWProxy {
  ModelChoice credentialId(String credentialId);

  ModelChoice model(String model);

  ModelChoice reasoningEffort(ReasoningEffort? reasoningEffort);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelChoice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelChoice(...).copyWith(id: 12, name: "My name")
  /// ```
  ModelChoice call({
    String credentialId,
    String model,
    ReasoningEffort? reasoningEffort,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfModelChoice.copyWith(...)` or call `instanceOfModelChoice.copyWith.fieldName(value)` for a single field.
class _$ModelChoiceCWProxyImpl implements _$ModelChoiceCWProxy {
  const _$ModelChoiceCWProxyImpl(this._value);

  final ModelChoice _value;

  @override
  ModelChoice credentialId(String credentialId) =>
      call(credentialId: credentialId);

  @override
  ModelChoice model(String model) => call(model: model);

  @override
  ModelChoice reasoningEffort(ReasoningEffort? reasoningEffort) =>
      call(reasoningEffort: reasoningEffort);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelChoice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelChoice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ModelChoice call({
    Object? credentialId = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? reasoningEffort = const $CopyWithPlaceholder(),
  }) {
    return ModelChoice(
      credentialId:
          credentialId == const $CopyWithPlaceholder() || credentialId == null
          ? _value.credentialId
          // ignore: cast_nullable_to_non_nullable
          : credentialId as String,
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      reasoningEffort: reasoningEffort == const $CopyWithPlaceholder()
          ? _value.reasoningEffort
          // ignore: cast_nullable_to_non_nullable
          : reasoningEffort as ReasoningEffort?,
    );
  }
}

extension $ModelChoiceCopyWith on ModelChoice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfModelChoice.copyWith(...)` or `instanceOfModelChoice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelChoiceCWProxy get copyWith => _$ModelChoiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelChoice _$ModelChoiceFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ModelChoice',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['credential_id', 'model']);
    final val = ModelChoice(
      credentialId: $checkedConvert('credential_id', (v) => v as String),
      model: $checkedConvert('model', (v) => v as String),
      reasoningEffort: $checkedConvert(
        'reasoning_effort',
        (v) => $enumDecodeNullable(_$ReasoningEffortEnumMap, v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'credentialId': 'credential_id',
    'reasoningEffort': 'reasoning_effort',
  },
);

Map<String, dynamic> _$ModelChoiceToJson(ModelChoice instance) =>
    <String, dynamic>{
      'credential_id': instance.credentialId,
      'model': instance.model,
      'reasoning_effort': ?_$ReasoningEffortEnumMap[instance.reasoningEffort],
    };

const _$ReasoningEffortEnumMap = {
  ReasoningEffort.none: 'none',
  ReasoningEffort.low: 'low',
  ReasoningEffort.medium: 'medium',
  ReasoningEffort.high: 'high',
  ReasoningEffort.xhigh: 'xhigh',
  ReasoningEffort.max: 'max',
};
