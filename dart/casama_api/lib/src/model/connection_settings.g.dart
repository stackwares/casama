// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectionSettingsCWProxy {
  ConnectionSettings composio(ConnectionSettingsComposioEnum composio);

  ConnectionSettings composioKey(bool composioKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectionSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectionSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectionSettings call({
    ConnectionSettingsComposioEnum composio,
    bool composioKey,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectionSettings.copyWith(...)` or call `instanceOfConnectionSettings.copyWith.fieldName(value)` for a single field.
class _$ConnectionSettingsCWProxyImpl implements _$ConnectionSettingsCWProxy {
  const _$ConnectionSettingsCWProxyImpl(this._value);

  final ConnectionSettings _value;

  @override
  ConnectionSettings composio(ConnectionSettingsComposioEnum composio) =>
      call(composio: composio);

  @override
  ConnectionSettings composioKey(bool composioKey) =>
      call(composioKey: composioKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectionSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectionSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectionSettings call({
    Object? composio = const $CopyWithPlaceholder(),
    Object? composioKey = const $CopyWithPlaceholder(),
  }) {
    return ConnectionSettings(
      composio: composio == const $CopyWithPlaceholder() || composio == null
          ? _value.composio
          // ignore: cast_nullable_to_non_nullable
          : composio as ConnectionSettingsComposioEnum,
      composioKey:
          composioKey == const $CopyWithPlaceholder() || composioKey == null
          ? _value.composioKey
          // ignore: cast_nullable_to_non_nullable
          : composioKey as bool,
    );
  }
}

extension $ConnectionSettingsCopyWith on ConnectionSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectionSettings.copyWith(...)` or `instanceOfConnectionSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectionSettingsCWProxy get copyWith =>
      _$ConnectionSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionSettings _$ConnectionSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConnectionSettings', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['composio', 'composio_key']);
      final val = ConnectionSettings(
        composio: $checkedConvert(
          'composio',
          (v) => $enumDecode(_$ConnectionSettingsComposioEnumEnumMap, v),
        ),
        composioKey: $checkedConvert('composio_key', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'composioKey': 'composio_key'});

Map<String, dynamic> _$ConnectionSettingsToJson(ConnectionSettings instance) =>
    <String, dynamic>{
      'composio': _$ConnectionSettingsComposioEnumEnumMap[instance.composio]!,
      'composio_key': instance.composioKey,
    };

const _$ConnectionSettingsComposioEnumEnumMap = {
  ConnectionSettingsComposioEnum.server: 'server',
  ConnectionSettingsComposioEnum.own: 'own',
};
