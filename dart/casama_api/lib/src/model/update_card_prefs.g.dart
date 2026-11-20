// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_card_prefs.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateCardPrefsCWProxy {
  UpdateCardPrefs homePlace(Place? homePlace);

  UpdateCardPrefs units(CardUnits? units);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCardPrefs(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCardPrefs(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateCardPrefs call({Place? homePlace, CardUnits? units});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateCardPrefs.copyWith(...)` or call `instanceOfUpdateCardPrefs.copyWith.fieldName(value)` for a single field.
class _$UpdateCardPrefsCWProxyImpl implements _$UpdateCardPrefsCWProxy {
  const _$UpdateCardPrefsCWProxyImpl(this._value);

  final UpdateCardPrefs _value;

  @override
  UpdateCardPrefs homePlace(Place? homePlace) => call(homePlace: homePlace);

  @override
  UpdateCardPrefs units(CardUnits? units) => call(units: units);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateCardPrefs(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateCardPrefs(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateCardPrefs call({
    Object? homePlace = const $CopyWithPlaceholder(),
    Object? units = const $CopyWithPlaceholder(),
  }) {
    return UpdateCardPrefs(
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

extension $UpdateCardPrefsCopyWith on UpdateCardPrefs {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateCardPrefs.copyWith(...)` or `instanceOfUpdateCardPrefs.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateCardPrefsCWProxy get copyWith => _$UpdateCardPrefsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCardPrefs _$UpdateCardPrefsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateCardPrefs', json, ($checkedConvert) {
      final val = UpdateCardPrefs(
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

Map<String, dynamic> _$UpdateCardPrefsToJson(UpdateCardPrefs instance) =>
    <String, dynamic>{
      'home_place': ?instance.homePlace?.toJson(),
      'units': ?instance.units?.toJson(),
    };
