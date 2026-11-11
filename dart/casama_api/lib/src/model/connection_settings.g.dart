// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectionSettingsCWProxy {
  ConnectionSettings composio(ConnectionSettingsComposioEnum composio);

  ConnectionSettings google(ConnectionSettingsGoogleEnum google);

  ConnectionSettings composioKey(bool composioKey);

  ConnectionSettings googleDirectAvailable(bool googleDirectAvailable);

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
    ConnectionSettingsGoogleEnum google,
    bool composioKey,
    bool googleDirectAvailable,
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
  ConnectionSettings google(ConnectionSettingsGoogleEnum google) =>
      call(google: google);

  @override
  ConnectionSettings composioKey(bool composioKey) =>
      call(composioKey: composioKey);

  @override
  ConnectionSettings googleDirectAvailable(bool googleDirectAvailable) =>
      call(googleDirectAvailable: googleDirectAvailable);

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
    Object? google = const $CopyWithPlaceholder(),
    Object? composioKey = const $CopyWithPlaceholder(),
    Object? googleDirectAvailable = const $CopyWithPlaceholder(),
  }) {
    return ConnectionSettings(
      composio: composio == const $CopyWithPlaceholder() || composio == null
          ? _value.composio
          // ignore: cast_nullable_to_non_nullable
          : composio as ConnectionSettingsComposioEnum,
      google: google == const $CopyWithPlaceholder() || google == null
          ? _value.google
          // ignore: cast_nullable_to_non_nullable
          : google as ConnectionSettingsGoogleEnum,
      composioKey:
          composioKey == const $CopyWithPlaceholder() || composioKey == null
          ? _value.composioKey
          // ignore: cast_nullable_to_non_nullable
          : composioKey as bool,
      googleDirectAvailable:
          googleDirectAvailable == const $CopyWithPlaceholder() ||
              googleDirectAvailable == null
          ? _value.googleDirectAvailable
          // ignore: cast_nullable_to_non_nullable
          : googleDirectAvailable as bool,
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
    $checkedCreate(
      'ConnectionSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'composio',
            'google',
            'composio_key',
            'google_direct_available',
          ],
        );
        final val = ConnectionSettings(
          composio: $checkedConvert(
            'composio',
            (v) => $enumDecode(_$ConnectionSettingsComposioEnumEnumMap, v),
          ),
          google: $checkedConvert(
            'google',
            (v) => $enumDecode(_$ConnectionSettingsGoogleEnumEnumMap, v),
          ),
          composioKey: $checkedConvert('composio_key', (v) => v as bool),
          googleDirectAvailable: $checkedConvert(
            'google_direct_available',
            (v) => v as bool,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'composioKey': 'composio_key',
        'googleDirectAvailable': 'google_direct_available',
      },
    );

Map<String, dynamic> _$ConnectionSettingsToJson(ConnectionSettings instance) =>
    <String, dynamic>{
      'composio': _$ConnectionSettingsComposioEnumEnumMap[instance.composio]!,
      'google': _$ConnectionSettingsGoogleEnumEnumMap[instance.google]!,
      'composio_key': instance.composioKey,
      'google_direct_available': instance.googleDirectAvailable,
    };

const _$ConnectionSettingsComposioEnumEnumMap = {
  ConnectionSettingsComposioEnum.server: 'server',
  ConnectionSettingsComposioEnum.own: 'own',
};

const _$ConnectionSettingsGoogleEnumEnumMap = {
  ConnectionSettingsGoogleEnum.composio: 'composio',
  ConnectionSettingsGoogleEnum.direct: 'direct',
};
