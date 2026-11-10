// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_integration_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateIntegrationRequestCWProxy {
  UpdateIntegrationRequest riskOverrides(
    Map<String, UpdateIntegrationRequestRiskOverridesEnum>? riskOverrides,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateIntegrationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateIntegrationRequest call({
    Map<String, UpdateIntegrationRequestRiskOverridesEnum>? riskOverrides,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateIntegrationRequest.copyWith(...)` or call `instanceOfUpdateIntegrationRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateIntegrationRequestCWProxyImpl
    implements _$UpdateIntegrationRequestCWProxy {
  const _$UpdateIntegrationRequestCWProxyImpl(this._value);

  final UpdateIntegrationRequest _value;

  @override
  UpdateIntegrationRequest riskOverrides(
    Map<String, UpdateIntegrationRequestRiskOverridesEnum>? riskOverrides,
  ) => call(riskOverrides: riskOverrides);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateIntegrationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateIntegrationRequest call({
    Object? riskOverrides = const $CopyWithPlaceholder(),
  }) {
    return UpdateIntegrationRequest(
      riskOverrides: riskOverrides == const $CopyWithPlaceholder()
          ? _value.riskOverrides
          // ignore: cast_nullable_to_non_nullable
          : riskOverrides
                as Map<String, UpdateIntegrationRequestRiskOverridesEnum>?,
    );
  }
}

extension $UpdateIntegrationRequestCopyWith on UpdateIntegrationRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateIntegrationRequest.copyWith(...)` or `instanceOfUpdateIntegrationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateIntegrationRequestCWProxy get copyWith =>
      _$UpdateIntegrationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateIntegrationRequest _$UpdateIntegrationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateIntegrationRequest', json, ($checkedConvert) {
  final val = UpdateIntegrationRequest(
    riskOverrides: $checkedConvert(
      'risk_overrides',
      (v) => (v as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          $enumDecode(_$UpdateIntegrationRequestRiskOverridesEnumEnumMap, e),
        ),
      ),
    ),
  );
  return val;
}, fieldKeyMap: const {'riskOverrides': 'risk_overrides'});

Map<String, dynamic> _$UpdateIntegrationRequestToJson(
  UpdateIntegrationRequest instance,
) => <String, dynamic>{
  'risk_overrides': ?instance.riskOverrides?.map(
    (k, e) =>
        MapEntry(k, _$UpdateIntegrationRequestRiskOverridesEnumEnumMap[e]!),
  ),
};

const _$UpdateIntegrationRequestRiskOverridesEnumEnumMap = {
  UpdateIntegrationRequestRiskOverridesEnum.low: 'low',
  UpdateIntegrationRequestRiskOverridesEnum.medium: 'medium',
  UpdateIntegrationRequestRiskOverridesEnum.high: 'high',
};
