// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_units.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardUnitsCWProxy {
  CardUnits temp(CardUnitsTempEnum? temp);

  CardUnits wind(CardUnitsWindEnum? wind);

  CardUnits precip(CardUnitsPrecipEnum? precip);

  CardUnits distance(CardUnitsDistanceEnum? distance);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardUnits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardUnits(...).copyWith(id: 12, name: "My name")
  /// ```
  CardUnits call({
    CardUnitsTempEnum? temp,
    CardUnitsWindEnum? wind,
    CardUnitsPrecipEnum? precip,
    CardUnitsDistanceEnum? distance,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCardUnits.copyWith(...)` or call `instanceOfCardUnits.copyWith.fieldName(value)` for a single field.
class _$CardUnitsCWProxyImpl implements _$CardUnitsCWProxy {
  const _$CardUnitsCWProxyImpl(this._value);

  final CardUnits _value;

  @override
  CardUnits temp(CardUnitsTempEnum? temp) => call(temp: temp);

  @override
  CardUnits wind(CardUnitsWindEnum? wind) => call(wind: wind);

  @override
  CardUnits precip(CardUnitsPrecipEnum? precip) => call(precip: precip);

  @override
  CardUnits distance(CardUnitsDistanceEnum? distance) =>
      call(distance: distance);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CardUnits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CardUnits(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CardUnits call({
    Object? temp = const $CopyWithPlaceholder(),
    Object? wind = const $CopyWithPlaceholder(),
    Object? precip = const $CopyWithPlaceholder(),
    Object? distance = const $CopyWithPlaceholder(),
  }) {
    return CardUnits(
      temp: temp == const $CopyWithPlaceholder()
          ? _value.temp
          // ignore: cast_nullable_to_non_nullable
          : temp as CardUnitsTempEnum?,
      wind: wind == const $CopyWithPlaceholder()
          ? _value.wind
          // ignore: cast_nullable_to_non_nullable
          : wind as CardUnitsWindEnum?,
      precip: precip == const $CopyWithPlaceholder()
          ? _value.precip
          // ignore: cast_nullable_to_non_nullable
          : precip as CardUnitsPrecipEnum?,
      distance: distance == const $CopyWithPlaceholder()
          ? _value.distance
          // ignore: cast_nullable_to_non_nullable
          : distance as CardUnitsDistanceEnum?,
    );
  }
}

extension $CardUnitsCopyWith on CardUnits {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCardUnits.copyWith(...)` or `instanceOfCardUnits.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardUnitsCWProxy get copyWith => _$CardUnitsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardUnits _$CardUnitsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CardUnits', json, ($checkedConvert) {
      final val = CardUnits(
        temp: $checkedConvert(
          'temp',
          (v) => $enumDecodeNullable(_$CardUnitsTempEnumEnumMap, v),
        ),
        wind: $checkedConvert(
          'wind',
          (v) => $enumDecodeNullable(_$CardUnitsWindEnumEnumMap, v),
        ),
        precip: $checkedConvert(
          'precip',
          (v) => $enumDecodeNullable(_$CardUnitsPrecipEnumEnumMap, v),
        ),
        distance: $checkedConvert(
          'distance',
          (v) => $enumDecodeNullable(_$CardUnitsDistanceEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CardUnitsToJson(CardUnits instance) => <String, dynamic>{
  'temp': ?_$CardUnitsTempEnumEnumMap[instance.temp],
  'wind': ?_$CardUnitsWindEnumEnumMap[instance.wind],
  'precip': ?_$CardUnitsPrecipEnumEnumMap[instance.precip],
  'distance': ?_$CardUnitsDistanceEnumEnumMap[instance.distance],
};

const _$CardUnitsTempEnumEnumMap = {
  CardUnitsTempEnum.C: 'C',
  CardUnitsTempEnum.F: 'F',
};

const _$CardUnitsWindEnumEnumMap = {
  CardUnitsWindEnum.kph: 'kph',
  CardUnitsWindEnum.mph: 'mph',
  CardUnitsWindEnum.ms: 'ms',
  CardUnitsWindEnum.kn: 'kn',
};

const _$CardUnitsPrecipEnumEnumMap = {
  CardUnitsPrecipEnum.mm: 'mm',
  CardUnitsPrecipEnum.in_: 'in',
};

const _$CardUnitsDistanceEnumEnumMap = {
  CardUnitsDistanceEnum.km: 'km',
  CardUnitsDistanceEnum.mi: 'mi',
};
