// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_tools_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationToolsInnerCWProxy {
  IntegrationToolsInner name(String name);

  IntegrationToolsInner description(String description);

  IntegrationToolsInner risk(Risk? risk);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationToolsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationToolsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  IntegrationToolsInner call({String name, String description, Risk? risk});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIntegrationToolsInner.copyWith(...)` or call `instanceOfIntegrationToolsInner.copyWith.fieldName(value)` for a single field.
class _$IntegrationToolsInnerCWProxyImpl
    implements _$IntegrationToolsInnerCWProxy {
  const _$IntegrationToolsInnerCWProxyImpl(this._value);

  final IntegrationToolsInner _value;

  @override
  IntegrationToolsInner name(String name) => call(name: name);

  @override
  IntegrationToolsInner description(String description) =>
      call(description: description);

  @override
  IntegrationToolsInner risk(Risk? risk) => call(risk: risk);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationToolsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationToolsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IntegrationToolsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
  }) {
    return IntegrationToolsInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as Risk?,
    );
  }
}

extension $IntegrationToolsInnerCopyWith on IntegrationToolsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIntegrationToolsInner.copyWith(...)` or `instanceOfIntegrationToolsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IntegrationToolsInnerCWProxy get copyWith =>
      _$IntegrationToolsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationToolsInner _$IntegrationToolsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('IntegrationToolsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'description']);
  final val = IntegrationToolsInner(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String),
    risk: $checkedConvert('risk', (v) => $enumDecodeNullable(_$RiskEnumMap, v)),
  );
  return val;
});

Map<String, dynamic> _$IntegrationToolsInnerToJson(
  IntegrationToolsInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'risk': ?_$RiskEnumMap[instance.risk],
};

const _$RiskEnumMap = {
  Risk.low: 'low',
  Risk.medium: 'medium',
  Risk.high: 'high',
};
