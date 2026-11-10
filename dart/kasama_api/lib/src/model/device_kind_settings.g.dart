// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_kind_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceKindSettingsCWProxy {
  DeviceKindSettings retentionDays(int? retentionDays);

  DeviceKindSettings privateModel(bool? privateModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceKindSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceKindSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceKindSettings call({int? retentionDays, bool? privateModel});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceKindSettings.copyWith(...)` or call `instanceOfDeviceKindSettings.copyWith.fieldName(value)` for a single field.
class _$DeviceKindSettingsCWProxyImpl implements _$DeviceKindSettingsCWProxy {
  const _$DeviceKindSettingsCWProxyImpl(this._value);

  final DeviceKindSettings _value;

  @override
  DeviceKindSettings retentionDays(int? retentionDays) =>
      call(retentionDays: retentionDays);

  @override
  DeviceKindSettings privateModel(bool? privateModel) =>
      call(privateModel: privateModel);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceKindSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceKindSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceKindSettings call({
    Object? retentionDays = const $CopyWithPlaceholder(),
    Object? privateModel = const $CopyWithPlaceholder(),
  }) {
    return DeviceKindSettings(
      retentionDays: retentionDays == const $CopyWithPlaceholder()
          ? _value.retentionDays
          // ignore: cast_nullable_to_non_nullable
          : retentionDays as int?,
      privateModel: privateModel == const $CopyWithPlaceholder()
          ? _value.privateModel
          // ignore: cast_nullable_to_non_nullable
          : privateModel as bool?,
    );
  }
}

extension $DeviceKindSettingsCopyWith on DeviceKindSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceKindSettings.copyWith(...)` or `instanceOfDeviceKindSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceKindSettingsCWProxy get copyWith =>
      _$DeviceKindSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceKindSettings _$DeviceKindSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeviceKindSettings',
      json,
      ($checkedConvert) {
        final val = DeviceKindSettings(
          retentionDays: $checkedConvert(
            'retention_days',
            (v) => (v as num?)?.toInt(),
          ),
          privateModel: $checkedConvert('private_model', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'retentionDays': 'retention_days',
        'privateModel': 'private_model',
      },
    );

Map<String, dynamic> _$DeviceKindSettingsToJson(DeviceKindSettings instance) =>
    <String, dynamic>{
      'retention_days': ?instance.retentionDays,
      'private_model': ?instance.privateModel,
    };
