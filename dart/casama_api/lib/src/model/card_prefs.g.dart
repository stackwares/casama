// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_prefs.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardPrefsCWProxy {
  CardPrefs homePlace(Place? homePlace);

  CardPrefs units(CardUnits? units);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardPrefs(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardPrefs(...).copyWith(id: 12, name: "My name")
  /// ```
  CardPrefs call({Place? homePlace, CardUnits? units});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCardPrefs.copyWith(...)` or call `instanceOfCardPrefs.copyWith.fieldName(value)` for a single field.
class _$CardPrefsCWProxyImpl implements _$CardPrefsCWProxy {
  const _$CardPrefsCWProxyImpl(this._value);

  final CardPrefs _value;

  @override
  CardPrefs homePlace(Place? homePlace) => call(homePlace: homePlace);

  @override
  CardPrefs units(CardUnits? units) => call(units: units);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardPrefs(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardPrefs(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CardPrefs call({
    Object? homePlace = const $CopyWithPlaceholder(),
    Object? units = const $CopyWithPlaceholder(),
  }) {
    return CardPrefs(
      homePlace: homePlace == const $CopyWithPlaceholder()
          ? _value.homePlace
          // ignore: cast_nullable_to_non_nullable
          : homePlace as Place?,
      units: units == const $CopyWithPlaceholder()
          ? _value.units
          // ignore: cast_nullable_to_non_nullable
          : units as CardUnits?,
    );
  }
}

extension $CardPrefsCopyWith on CardPrefs {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCardPrefs.copyWith(...)` or `instanceOfCardPrefs.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardPrefsCWProxy get copyWith => _$CardPrefsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardPrefs _$CardPrefsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CardPrefs', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['home_place', 'units']);
      final val = CardPrefs(
        homePlace: $checkedConvert(
          'home_place',
          (v) => v == null ? null : Place.fromJson(v as Map<String, dynamic>),
        ),
        units: $checkedConvert(
          'units',
          (v) =>
              v == null ? null : CardUnits.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'homePlace': 'home_place'});

Map<String, dynamic> _$CardPrefsToJson(CardPrefs instance) => <String, dynamic>{
  'home_place': instance.homePlace?.toJson(),
  'units': instance.units?.toJson(),
};
