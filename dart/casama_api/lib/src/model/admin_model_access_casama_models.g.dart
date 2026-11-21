// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_model_access_casama_models.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminModelAccessCasamaModelsCWProxy {
  AdminModelAccessCasamaModels default_(
    AdminModelAccessCasamaModelsDefault_Enum default_,
  );

  AdminModelAccessCasamaModels plans(
    Map<String, AdminModelAccessCasamaModelsPlansEnum> plans,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminModelAccessCasamaModels(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminModelAccessCasamaModels(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminModelAccessCasamaModels call({
    AdminModelAccessCasamaModelsDefault_Enum default_,
    Map<String, AdminModelAccessCasamaModelsPlansEnum> plans,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminModelAccessCasamaModels.copyWith(...)` or call `instanceOfAdminModelAccessCasamaModels.copyWith.fieldName(value)` for a single field.
class _$AdminModelAccessCasamaModelsCWProxyImpl
    implements _$AdminModelAccessCasamaModelsCWProxy {
  const _$AdminModelAccessCasamaModelsCWProxyImpl(this._value);

  final AdminModelAccessCasamaModels _value;

  @override
  AdminModelAccessCasamaModels default_(
    AdminModelAccessCasamaModelsDefault_Enum default_,
  ) => call(default_: default_);

  @override
  AdminModelAccessCasamaModels plans(
    Map<String, AdminModelAccessCasamaModelsPlansEnum> plans,
  ) => call(plans: plans);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminModelAccessCasamaModels(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminModelAccessCasamaModels(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminModelAccessCasamaModels call({
    Object? default_ = const $CopyWithPlaceholder(),
    Object? plans = const $CopyWithPlaceholder(),
  }) {
    return AdminModelAccessCasamaModels(
      default_: default_ == const $CopyWithPlaceholder() || default_ == null
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as AdminModelAccessCasamaModelsDefault_Enum,
      plans: plans == const $CopyWithPlaceholder() || plans == null
          ? _value.plans
          // ignore: cast_nullable_to_non_nullable
          : plans as Map<String, AdminModelAccessCasamaModelsPlansEnum>,
    );
  }
}

extension $AdminModelAccessCasamaModelsCopyWith
    on AdminModelAccessCasamaModels {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminModelAccessCasamaModels.copyWith(...)` or `instanceOfAdminModelAccessCasamaModels.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminModelAccessCasamaModelsCWProxy get copyWith =>
      _$AdminModelAccessCasamaModelsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminModelAccessCasamaModels _$AdminModelAccessCasamaModelsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminModelAccessCasamaModels', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['default', 'plans']);
  final val = AdminModelAccessCasamaModels(
    default_: $checkedConvert(
      'default',
      (v) => $enumDecode(_$AdminModelAccessCasamaModelsDefault_EnumEnumMap, v),
    ),
    plans: $checkedConvert(
      'plans',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          $enumDecode(_$AdminModelAccessCasamaModelsPlansEnumEnumMap, e),
        ),
      ),
    ),
  );
  return val;
}, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$AdminModelAccessCasamaModelsToJson(
  AdminModelAccessCasamaModels instance,
) => <String, dynamic>{
  'default':
      _$AdminModelAccessCasamaModelsDefault_EnumEnumMap[instance.default_]!,
  'plans': instance.plans.map(
    (k, e) => MapEntry(k, _$AdminModelAccessCasamaModelsPlansEnumEnumMap[e]!),
  ),
};

const _$AdminModelAccessCasamaModelsDefault_EnumEnumMap = {
  AdminModelAccessCasamaModelsDefault_Enum.on_: 'on',
  AdminModelAccessCasamaModelsDefault_Enum.off: 'off',
};

const _$AdminModelAccessCasamaModelsPlansEnumEnumMap = {
  AdminModelAccessCasamaModelsPlansEnum.on_: 'on',
  AdminModelAccessCasamaModelsPlansEnum.off: 'off',
};
