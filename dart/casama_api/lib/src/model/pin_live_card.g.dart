// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_live_card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PinLiveCardCWProxy {
  PinLiveCard units(CardUnits? units);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PinLiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PinLiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  PinLiveCard call({CardUnits? units});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPinLiveCard.copyWith(...)` or call `instanceOfPinLiveCard.copyWith.fieldName(value)` for a single field.
class _$PinLiveCardCWProxyImpl implements _$PinLiveCardCWProxy {
  const _$PinLiveCardCWProxyImpl(this._value);

  final PinLiveCard _value;

  @override
  PinLiveCard units(CardUnits? units) => call(units: units);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PinLiveCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PinLiveCard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PinLiveCard call({Object? units = const $CopyWithPlaceholder()}) {
    return PinLiveCard(
      units: units == const $CopyWithPlaceholder()
          ? _value.units
          // ignore: cast_nullable_to_non_nullable
          : units as CardUnits?,
    );
  }
}

extension $PinLiveCardCopyWith on PinLiveCard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPinLiveCard.copyWith(...)` or `instanceOfPinLiveCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PinLiveCardCWProxy get copyWith => _$PinLiveCardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinLiveCard _$PinLiveCardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PinLiveCard', json, ($checkedConvert) {
      final val = PinLiveCard(
        units: $checkedConvert(
          'units',
          (v) =>
              v == null ? null : CardUnits.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PinLiveCardToJson(PinLiveCard instance) =>
    <String, dynamic>{'units': ?instance.units?.toJson()};
