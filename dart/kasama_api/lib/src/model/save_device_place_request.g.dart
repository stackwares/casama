// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_device_place_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveDevicePlaceRequestCWProxy {
  SaveDevicePlaceRequest name(String name);

  SaveDevicePlaceRequest latitude(num latitude);

  SaveDevicePlaceRequest longitude(num longitude);

  SaveDevicePlaceRequest radiusM(int? radiusM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveDevicePlaceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveDevicePlaceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveDevicePlaceRequest call({
    String name,
    num latitude,
    num longitude,
    int? radiusM,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveDevicePlaceRequest.copyWith(...)` or call `instanceOfSaveDevicePlaceRequest.copyWith.fieldName(value)` for a single field.
class _$SaveDevicePlaceRequestCWProxyImpl
    implements _$SaveDevicePlaceRequestCWProxy {
  const _$SaveDevicePlaceRequestCWProxyImpl(this._value);

  final SaveDevicePlaceRequest _value;

  @override
  SaveDevicePlaceRequest name(String name) => call(name: name);

  @override
  SaveDevicePlaceRequest latitude(num latitude) => call(latitude: latitude);

  @override
  SaveDevicePlaceRequest longitude(num longitude) => call(longitude: longitude);

  @override
  SaveDevicePlaceRequest radiusM(int? radiusM) => call(radiusM: radiusM);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveDevicePlaceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveDevicePlaceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveDevicePlaceRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? latitude = const $CopyWithPlaceholder(),
    Object? longitude = const $CopyWithPlaceholder(),
    Object? radiusM = const $CopyWithPlaceholder(),
  }) {
    return SaveDevicePlaceRequest(
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
      radiusM: radiusM == const $CopyWithPlaceholder()
          ? _value.radiusM
          // ignore: cast_nullable_to_non_nullable
          : radiusM as int?,
    );
  }
}

extension $SaveDevicePlaceRequestCopyWith on SaveDevicePlaceRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveDevicePlaceRequest.copyWith(...)` or `instanceOfSaveDevicePlaceRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveDevicePlaceRequestCWProxy get copyWith =>
      _$SaveDevicePlaceRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveDevicePlaceRequest _$SaveDevicePlaceRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveDevicePlaceRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'latitude', 'longitude']);
  final val = SaveDevicePlaceRequest(
    name: $checkedConvert('name', (v) => v as String),
    latitude: $checkedConvert('latitude', (v) => v as num),
    longitude: $checkedConvert('longitude', (v) => v as num),
    radiusM: $checkedConvert('radius_m', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'radiusM': 'radius_m'});

Map<String, dynamic> _$SaveDevicePlaceRequestToJson(
  SaveDevicePlaceRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'radius_m': ?instance.radiusM,
};
