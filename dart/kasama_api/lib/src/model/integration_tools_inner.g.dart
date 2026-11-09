// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_tools_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationToolsInnerCWProxy {
  IntegrationToolsInner name(String name);

  IntegrationToolsInner description(String description);

  IntegrationToolsInner risk(Risk? risk);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntegrationToolsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntegrationToolsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  IntegrationToolsInner call({String name, String description, Risk? risk});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIntegrationToolsInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIntegrationToolsInner.copyWith.fieldName(...)`
class _$IntegrationToolsInnerCWProxyImpl
    implements _$IntegrationToolsInnerCWProxy {
  const _$IntegrationToolsInnerCWProxyImpl(this._value);

  final IntegrationToolsInner _value;

  @override
  IntegrationToolsInner name(String name) => this(name: name);

  @override
  IntegrationToolsInner description(String description) =>
      this(description: description);

  @override
  IntegrationToolsInner risk(Risk? risk) => this(risk: risk);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntegrationToolsInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntegrationToolsInner(...).copyWith(id: 12, name: "My name")
  /// ````
  IntegrationToolsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
  }) {
    return IntegrationToolsInner(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfIntegrationToolsInner.copyWith(...)` or like so:`instanceOfIntegrationToolsInner.copyWith.fieldName(...)`.
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
