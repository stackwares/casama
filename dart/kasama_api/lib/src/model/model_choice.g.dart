// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_choice.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelChoiceCWProxy {
  ModelChoice credentialId(String credentialId);

  ModelChoice model(String model);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModelChoice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModelChoice(...).copyWith(id: 12, name: "My name")
  /// ````
  ModelChoice call({String credentialId, String model});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModelChoice.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModelChoice.copyWith.fieldName(...)`
class _$ModelChoiceCWProxyImpl implements _$ModelChoiceCWProxy {
  const _$ModelChoiceCWProxyImpl(this._value);

  final ModelChoice _value;

  @override
  ModelChoice credentialId(String credentialId) =>
      this(credentialId: credentialId);

  @override
  ModelChoice model(String model) => this(model: model);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModelChoice(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModelChoice(...).copyWith(id: 12, name: "My name")
  /// ````
  ModelChoice call({
    Object? credentialId = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
  }) {
    return ModelChoice(
      credentialId: credentialId == const $CopyWithPlaceholder()
          ? _value.credentialId
          // ignore: cast_nullable_to_non_nullable
          : credentialId as String,
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
    );
  }
}

extension $ModelChoiceCopyWith on ModelChoice {
  /// Returns a callable class that can be used as follows: `instanceOfModelChoice.copyWith(...)` or like so:`instanceOfModelChoice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelChoiceCWProxy get copyWith => _$ModelChoiceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelChoice _$ModelChoiceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ModelChoice', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['credential_id', 'model']);
      final val = ModelChoice(
        credentialId: $checkedConvert('credential_id', (v) => v as String),
        model: $checkedConvert('model', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'credentialId': 'credential_id'});

Map<String, dynamic> _$ModelChoiceToJson(ModelChoice instance) =>
    <String, dynamic>{
      'credential_id': instance.credentialId,
      'model': instance.model,
    };
