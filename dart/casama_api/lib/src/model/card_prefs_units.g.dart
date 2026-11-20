// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_prefs_units.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardPrefsUnitsCWProxy {
  CardPrefsUnits temp(CardPrefsUnitsTempEnum? temp);

  CardPrefsUnits wind(CardPrefsUnitsWindEnum? wind);

  CardPrefsUnits precip(CardPrefsUnitsPrecipEnum? precip);

  CardPrefsUnits distance(CardPrefsUnitsDistanceEnum? distance);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardPrefsUnits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardPrefsUnits(...).copyWith(id: 12, name: "My name")
  /// ```
  CardPrefsUnits call({
    CardPrefsUnitsTempEnum? temp,
    CardPrefsUnitsWindEnum? wind,
    CardPrefsUnitsPrecipEnum? precip,
    CardPrefsUnitsDistanceEnum? distance,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCardPrefsUnits.copyWith(...)` or call `instanceOfCardPrefsUnits.copyWith.fieldName(value)` for a single field.
class _$CardPrefsUnitsCWProxyImpl implements _$CardPrefsUnitsCWProxy {
  const _$CardPrefsUnitsCWProxyImpl(this._value);

  final CardPrefsUnits _value;

  @override
  CardPrefsUnits temp(CardPrefsUnitsTempEnum? temp) => call(temp: temp);

  @override
  CardPrefsUnits wind(CardPrefsUnitsWindEnum? wind) => call(wind: wind);

  @override
  CardPrefsUnits precip(CardPrefsUnitsPrecipEnum? precip) =>
      call(precip: precip);

  @override
  CardPrefsUnits distance(CardPrefsUnitsDistanceEnum? distance) =>
      call(distance: distance);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardPrefsUnits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardPrefsUnits(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CardPrefsUnits call({
    Object? temp = const $CopyWithPlaceholder(),
    Object? wind = const $CopyWithPlaceholder(),
    Object? precip = const $CopyWithPlaceholder(),
    Object? distance = const $CopyWithPlaceholder(),
  }) {
    return CardPrefsUnits(
      temp: temp == const $CopyWithPlaceholder()
          ? _value.temp
          // ignore: cast_nullable_to_non_nullable
          : temp as CardPrefsUnitsTempEnum?,
      wind: wind == const $CopyWithPlaceholder()
          ? _value.wind
          // ignore: cast_nullable_to_non_nullable
          : wind as CardPrefsUnitsWindEnum?,
      precip: precip == const $CopyWithPlaceholder()
          ? _value.precip
          // ignore: cast_nullable_to_non_nullable
          : precip as CardPrefsUnitsPrecipEnum?,
      distance: distance == const $CopyWithPlaceholder()
          ? _value.distance
          // ignore: cast_nullable_to_non_nullable
          : distance as CardPrefsUnitsDistanceEnum?,
    );
  }
}

extension $CardPrefsUnitsCopyWith on CardPrefsUnits {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCardPrefsUnits.copyWith(...)` or `instanceOfCardPrefsUnits.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardPrefsUnitsCWProxy get copyWith => _$CardPrefsUnitsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardPrefsUnits _$CardPrefsUnitsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CardPrefsUnits', json, ($checkedConvert) {
      final val = CardPrefsUnits(
        temp: $checkedConvert(
          'temp',
          (v) => $enumDecodeNullable(_$CardPrefsUnitsTempEnumEnumMap, v),
        ),
        wind: $checkedConvert(
          'wind',
          (v) => $enumDecodeNullable(_$CardPrefsUnitsWindEnumEnumMap, v),
        ),
        precip: $checkedConvert(
          'precip',
          (v) => $enumDecodeNullable(_$CardPrefsUnitsPrecipEnumEnumMap, v),
        ),
        distance: $checkedConvert(
          'distance',
          (v) => $enumDecodeNullable(_$CardPrefsUnitsDistanceEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CardPrefsUnitsToJson(CardPrefsUnits instance) =>
    <String, dynamic>{
      'temp': ?_$CardPrefsUnitsTempEnumEnumMap[instance.temp],
      'wind': ?_$CardPrefsUnitsWindEnumEnumMap[instance.wind],
      'precip': ?_$CardPrefsUnitsPrecipEnumEnumMap[instance.precip],
      'distance': ?_$CardPrefsUnitsDistanceEnumEnumMap[instance.distance],
    };

const _$CardPrefsUnitsTempEnumEnumMap = {
  CardPrefsUnitsTempEnum.C: 'C',
  CardPrefsUnitsTempEnum.F: 'F',
};

const _$CardPrefsUnitsWindEnumEnumMap = {
  CardPrefsUnitsWindEnum.kph: 'kph',
  CardPrefsUnitsWindEnum.mph: 'mph',
  CardPrefsUnitsWindEnum.ms: 'ms',
  CardPrefsUnitsWindEnum.kn: 'kn',
};

const _$CardPrefsUnitsPrecipEnumEnumMap = {
  CardPrefsUnitsPrecipEnum.mm: 'mm',
  CardPrefsUnitsPrecipEnum.in_: 'in',
};

const _$CardPrefsUnitsDistanceEnumEnumMap = {
  CardPrefsUnitsDistanceEnum.km: 'km',
  CardPrefsUnitsDistanceEnum.mi: 'mi',
};
