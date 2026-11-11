// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_plugin_server_all_of_tools.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstalledPluginServerAllOfToolsCWProxy {
  InstalledPluginServerAllOfTools name(String name);

  InstalledPluginServerAllOfTools risk(
    InstalledPluginServerAllOfToolsRiskEnum risk,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstalledPluginServerAllOfTools(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstalledPluginServerAllOfTools(...).copyWith(id: 12, name: "My name")
  /// ```
  InstalledPluginServerAllOfTools call({
    String name,
    InstalledPluginServerAllOfToolsRiskEnum risk,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstalledPluginServerAllOfTools.copyWith(...)` or call `instanceOfInstalledPluginServerAllOfTools.copyWith.fieldName(value)` for a single field.
class _$InstalledPluginServerAllOfToolsCWProxyImpl
    implements _$InstalledPluginServerAllOfToolsCWProxy {
  const _$InstalledPluginServerAllOfToolsCWProxyImpl(this._value);

  final InstalledPluginServerAllOfTools _value;

  @override
  InstalledPluginServerAllOfTools name(String name) => call(name: name);

  @override
  InstalledPluginServerAllOfTools risk(
    InstalledPluginServerAllOfToolsRiskEnum risk,
  ) => call(risk: risk);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstalledPluginServerAllOfTools(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstalledPluginServerAllOfTools(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstalledPluginServerAllOfTools call({
    Object? name = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
  }) {
    return InstalledPluginServerAllOfTools(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      risk: risk == const $CopyWithPlaceholder() || risk == null
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as InstalledPluginServerAllOfToolsRiskEnum,
    );
  }
}

extension $InstalledPluginServerAllOfToolsCopyWith
    on InstalledPluginServerAllOfTools {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstalledPluginServerAllOfTools.copyWith(...)` or `instanceOfInstalledPluginServerAllOfTools.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstalledPluginServerAllOfToolsCWProxy get copyWith =>
      _$InstalledPluginServerAllOfToolsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstalledPluginServerAllOfTools _$InstalledPluginServerAllOfToolsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InstalledPluginServerAllOfTools', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'risk']);
  final val = InstalledPluginServerAllOfTools(
    name: $checkedConvert('name', (v) => v as String),
    risk: $checkedConvert(
      'risk',
      (v) => $enumDecode(_$InstalledPluginServerAllOfToolsRiskEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$InstalledPluginServerAllOfToolsToJson(
  InstalledPluginServerAllOfTools instance,
) => <String, dynamic>{
  'name': instance.name,
  'risk': _$InstalledPluginServerAllOfToolsRiskEnumEnumMap[instance.risk]!,
};

const _$InstalledPluginServerAllOfToolsRiskEnumEnumMap = {
  InstalledPluginServerAllOfToolsRiskEnum.low: 'low',
  InstalledPluginServerAllOfToolsRiskEnum.medium: 'medium',
  InstalledPluginServerAllOfToolsRiskEnum.high: 'high',
};
