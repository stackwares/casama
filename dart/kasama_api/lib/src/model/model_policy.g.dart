// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_policy.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelPolicyCWProxy {
  ModelPolicy primary(ModelChoice? primary);

  ModelPolicy fallbacks(List<ModelChoice>? fallbacks);

  ModelPolicy cheap(ModelChoice? cheap);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModelPolicy(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModelPolicy(...).copyWith(id: 12, name: "My name")
  /// ````
  ModelPolicy call({
    ModelChoice? primary,
    List<ModelChoice>? fallbacks,
    ModelChoice? cheap,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModelPolicy.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModelPolicy.copyWith.fieldName(...)`
class _$ModelPolicyCWProxyImpl implements _$ModelPolicyCWProxy {
  const _$ModelPolicyCWProxyImpl(this._value);

  final ModelPolicy _value;

  @override
  ModelPolicy primary(ModelChoice? primary) => this(primary: primary);

  @override
  ModelPolicy fallbacks(List<ModelChoice>? fallbacks) =>
      this(fallbacks: fallbacks);

  @override
  ModelPolicy cheap(ModelChoice? cheap) => this(cheap: cheap);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModelPolicy(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModelPolicy(...).copyWith(id: 12, name: "My name")
  /// ````
  ModelPolicy call({
    Object? primary = const $CopyWithPlaceholder(),
    Object? fallbacks = const $CopyWithPlaceholder(),
    Object? cheap = const $CopyWithPlaceholder(),
  }) {
    return ModelPolicy(
      primary: primary == const $CopyWithPlaceholder()
          ? _value.primary
          // ignore: cast_nullable_to_non_nullable
          : primary as ModelChoice?,
      fallbacks: fallbacks == const $CopyWithPlaceholder()
          ? _value.fallbacks
          // ignore: cast_nullable_to_non_nullable
          : fallbacks as List<ModelChoice>?,
      cheap: cheap == const $CopyWithPlaceholder()
          ? _value.cheap
          // ignore: cast_nullable_to_non_nullable
          : cheap as ModelChoice?,
    );
  }
}

extension $ModelPolicyCopyWith on ModelPolicy {
  /// Returns a callable class that can be used as follows: `instanceOfModelPolicy.copyWith(...)` or like so:`instanceOfModelPolicy.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelPolicyCWProxy get copyWith => _$ModelPolicyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelPolicy _$ModelPolicyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ModelPolicy',
  json,
  ($checkedConvert) {
    final val = ModelPolicy(
      primary: $checkedConvert(
        'primary',
        (v) =>
            v == null ? null : ModelChoice.fromJson(v as Map<String, dynamic>),
      ),
      fallbacks: $checkedConvert(
        'fallbacks',
        (v) => (v as List<dynamic>?)
            ?.map((e) => ModelChoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      cheap: $checkedConvert(
        'cheap',
        (v) =>
            v == null ? null : ModelChoice.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$ModelPolicyToJson(ModelPolicy instance) =>
    <String, dynamic>{
      'primary': ?instance.primary?.toJson(),
      'fallbacks': ?instance.fallbacks?.map((e) => e.toJson()).toList(),
      'cheap': ?instance.cheap?.toJson(),
    };
