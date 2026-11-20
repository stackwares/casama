// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_prefs_home_place.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardPrefsHomePlaceCWProxy {
  CardPrefsHomePlace name(String name);

  CardPrefsHomePlace region(String? region);

  CardPrefsHomePlace country(String? country);

  CardPrefsHomePlace countryName(String? countryName);

  CardPrefsHomePlace lat(num lat);

  CardPrefsHomePlace lng(num lng);

  CardPrefsHomePlace tz(String? tz);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardPrefsHomePlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardPrefsHomePlace(...).copyWith(id: 12, name: "My name")
  /// ```
  CardPrefsHomePlace call({
    String name,
    String? region,
    String? country,
    String? countryName,
    num lat,
    num lng,
    String? tz,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCardPrefsHomePlace.copyWith(...)` or call `instanceOfCardPrefsHomePlace.copyWith.fieldName(value)` for a single field.
class _$CardPrefsHomePlaceCWProxyImpl implements _$CardPrefsHomePlaceCWProxy {
  const _$CardPrefsHomePlaceCWProxyImpl(this._value);

  final CardPrefsHomePlace _value;

  @override
  CardPrefsHomePlace name(String name) => call(name: name);

  @override
  CardPrefsHomePlace region(String? region) => call(region: region);

  @override
  CardPrefsHomePlace country(String? country) => call(country: country);

  @override
  CardPrefsHomePlace countryName(String? countryName) =>
      call(countryName: countryName);

  @override
  CardPrefsHomePlace lat(num lat) => call(lat: lat);

  @override
  CardPrefsHomePlace lng(num lng) => call(lng: lng);

  @override
  CardPrefsHomePlace tz(String? tz) => call(tz: tz);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardPrefsHomePlace(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardPrefsHomePlace(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CardPrefsHomePlace call({
    Object? name = const $CopyWithPlaceholder(),
    Object? region = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
    Object? countryName = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
    Object? tz = const $CopyWithPlaceholder(),
  }) {
    return CardPrefsHomePlace(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      region: region == const $CopyWithPlaceholder()
          ? _value.region
          // ignore: cast_nullable_to_non_nullable
          : region as String?,
      country: country == const $CopyWithPlaceholder()
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String?,
      countryName: countryName == const $CopyWithPlaceholder()
          ? _value.countryName
          // ignore: cast_nullable_to_non_nullable
          : countryName as String?,
      lat: lat == const $CopyWithPlaceholder() || lat == null
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as num,
      lng: lng == const $CopyWithPlaceholder() || lng == null
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as num,
      tz: tz == const $CopyWithPlaceholder()
          ? _value.tz
          // ignore: cast_nullable_to_non_nullable
          : tz as String?,
    );
  }
}

extension $CardPrefsHomePlaceCopyWith on CardPrefsHomePlace {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCardPrefsHomePlace.copyWith(...)` or `instanceOfCardPrefsHomePlace.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardPrefsHomePlaceCWProxy get copyWith =>
      _$CardPrefsHomePlaceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardPrefsHomePlace _$CardPrefsHomePlaceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CardPrefsHomePlace', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'lat', 'lng']);
      final val = CardPrefsHomePlace(
        name: $checkedConvert('name', (v) => v as String),
        region: $checkedConvert('region', (v) => v as String?),
        country: $checkedConvert('country', (v) => v as String?),
        countryName: $checkedConvert('country_name', (v) => v as String?),
        lat: $checkedConvert('lat', (v) => v as num),
        lng: $checkedConvert('lng', (v) => v as num),
        tz: $checkedConvert('tz', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'countryName': 'country_name'});

Map<String, dynamic> _$CardPrefsHomePlaceToJson(CardPrefsHomePlace instance) =>
    <String, dynamic>{
      'name': instance.name,
      'region': ?instance.region,
      'country': ?instance.country,
      'country_name': ?instance.countryName,
      'lat': instance.lat,
      'lng': instance.lng,
      'tz': ?instance.tz,
    };
