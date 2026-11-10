// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_place.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DevicePlaceCWProxy {
  DevicePlace id(String id);

  DevicePlace name(String name);

  DevicePlace latitude(num latitude);

  DevicePlace longitude(num longitude);

  DevicePlace radiusM(int radiusM);

  DevicePlace createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DevicePlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePlace(...).copyWith(id: 12, name: "My name")
  /// ```
  DevicePlace call({
    String id,
    String name,
    num latitude,
    num longitude,
    int radiusM,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDevicePlace.copyWith(...)` or call `instanceOfDevicePlace.copyWith.fieldName(value)` for a single field.
class _$DevicePlaceCWProxyImpl implements _$DevicePlaceCWProxy {
  const _$DevicePlaceCWProxyImpl(this._value);

  final DevicePlace _value;

  @override
  DevicePlace id(String id) => call(id: id);

  @override
  DevicePlace name(String name) => call(name: name);

  @override
  DevicePlace latitude(num latitude) => call(latitude: latitude);

  @override
  DevicePlace longitude(num longitude) => call(longitude: longitude);

  @override
  DevicePlace radiusM(int radiusM) => call(radiusM: radiusM);

  @override
  DevicePlace createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DevicePlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePlace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DevicePlace call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? latitude = const $CopyWithPlaceholder(),
    Object? longitude = const $CopyWithPlaceholder(),
    Object? radiusM = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return DevicePlace(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      latitude: latitude == const $CopyWithPlaceholder() || latitude == null
          ? _value.latitude
          // ignore: cast_nullable_to_non_nullable
          : latitude as num,
      longitude: longitude == const $CopyWithPlaceholder() || longitude == null
          ? _value.longitude
          // ignore: cast_nullable_to_non_nullable
          : longitude as num,
      radiusM: radiusM == const $CopyWithPlaceholder() || radiusM == null
          ? _value.radiusM
          // ignore: cast_nullable_to_non_nullable
          : radiusM as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $DevicePlaceCopyWith on DevicePlace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDevicePlace.copyWith(...)` or `instanceOfDevicePlace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DevicePlaceCWProxy get copyWith => _$DevicePlaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePlace _$DevicePlaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DevicePlace', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'latitude',
          'longitude',
          'radius_m',
          'created_at',
        ],
      );
      final val = DevicePlace(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        latitude: $checkedConvert('latitude', (v) => v as num),
        longitude: $checkedConvert('longitude', (v) => v as num),
        radiusM: $checkedConvert('radius_m', (v) => (v as num).toInt()),
        createdAt: $checkedConvert(
          'created_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'radiusM': 'radius_m', 'createdAt': 'created_at'});

Map<String, dynamic> _$DevicePlaceToJson(DevicePlace instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius_m': instance.radiusM,
      'created_at': instance.createdAt.toIso8601String(),
    };
