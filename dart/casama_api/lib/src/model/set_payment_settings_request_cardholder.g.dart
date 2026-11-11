// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_payment_settings_request_cardholder.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetPaymentSettingsRequestCardholderCWProxy {
  SetPaymentSettingsRequestCardholder name(String name);

  SetPaymentSettingsRequestCardholder email(String email);

  SetPaymentSettingsRequestCardholder line1(String line1);

  SetPaymentSettingsRequestCardholder city(String city);

  SetPaymentSettingsRequestCardholder state(String? state);

  SetPaymentSettingsRequestCardholder postalCode(String postalCode);

  SetPaymentSettingsRequestCardholder country(String country);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetPaymentSettingsRequestCardholder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetPaymentSettingsRequestCardholder(...).copyWith(id: 12, name: "My name")
  /// ```
  SetPaymentSettingsRequestCardholder call({
    String name,
    String email,
    String line1,
    String city,
    String? state,
    String postalCode,
    String country,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetPaymentSettingsRequestCardholder.copyWith(...)` or call `instanceOfSetPaymentSettingsRequestCardholder.copyWith.fieldName(value)` for a single field.
class _$SetPaymentSettingsRequestCardholderCWProxyImpl
    implements _$SetPaymentSettingsRequestCardholderCWProxy {
  const _$SetPaymentSettingsRequestCardholderCWProxyImpl(this._value);

  final SetPaymentSettingsRequestCardholder _value;

  @override
  SetPaymentSettingsRequestCardholder name(String name) => call(name: name);

  @override
  SetPaymentSettingsRequestCardholder email(String email) => call(email: email);

  @override
  SetPaymentSettingsRequestCardholder line1(String line1) => call(line1: line1);

  @override
  SetPaymentSettingsRequestCardholder city(String city) => call(city: city);

  @override
  SetPaymentSettingsRequestCardholder state(String? state) =>
      call(state: state);

  @override
  SetPaymentSettingsRequestCardholder postalCode(String postalCode) =>
      call(postalCode: postalCode);

  @override
  SetPaymentSettingsRequestCardholder country(String country) =>
      call(country: country);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetPaymentSettingsRequestCardholder(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetPaymentSettingsRequestCardholder(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetPaymentSettingsRequestCardholder call({
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? line1 = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? postalCode = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
  }) {
    return SetPaymentSettingsRequestCardholder(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      line1: line1 == const $CopyWithPlaceholder() || line1 == null
          ? _value.line1
          // ignore: cast_nullable_to_non_nullable
          : line1 as String,
      city: city == const $CopyWithPlaceholder() || city == null
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as String?,
      postalCode:
          postalCode == const $CopyWithPlaceholder() || postalCode == null
          ? _value.postalCode
          // ignore: cast_nullable_to_non_nullable
          : postalCode as String,
      country: country == const $CopyWithPlaceholder() || country == null
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String,
    );
  }
}

extension $SetPaymentSettingsRequestCardholderCopyWith
    on SetPaymentSettingsRequestCardholder {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetPaymentSettingsRequestCardholder.copyWith(...)` or `instanceOfSetPaymentSettingsRequestCardholder.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetPaymentSettingsRequestCardholderCWProxy get copyWith =>
      _$SetPaymentSettingsRequestCardholderCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetPaymentSettingsRequestCardholder
_$SetPaymentSettingsRequestCardholderFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetPaymentSettingsRequestCardholder', json, (
      $checkedConvert,
    ) {
      $checkKeys(
        json,
        requiredKeys: const [
          'name',
          'email',
          'line1',
          'city',
          'postal_code',
          'country',
        ],
      );
      final val = SetPaymentSettingsRequestCardholder(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        line1: $checkedConvert('line1', (v) => v as String),
        city: $checkedConvert('city', (v) => v as String),
        state: $checkedConvert('state', (v) => v as String?),
        postalCode: $checkedConvert('postal_code', (v) => v as String),
        country: $checkedConvert('country', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'postalCode': 'postal_code'});

Map<String, dynamic> _$SetPaymentSettingsRequestCardholderToJson(
  SetPaymentSettingsRequestCardholder instance,
) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'line1': instance.line1,
  'city': instance.city,
  'state': ?instance.state,
  'postal_code': instance.postalCode,
  'country': instance.country,
};
