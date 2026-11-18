// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_contact.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainContactCWProxy {
  DomainContact firstName(String firstName);

  DomainContact lastName(String lastName);

  DomainContact organization(String? organization);

  DomainContact address1(String address1);

  DomainContact address2(String? address2);

  DomainContact city(String city);

  DomainContact state(String state);

  DomainContact zip(String zip);

  DomainContact country(String country);

  DomainContact phone(String phone);

  DomainContact email(String email);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainContact(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainContact(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainContact call({
    String firstName,
    String lastName,
    String? organization,
    String address1,
    String? address2,
    String city,
    String state,
    String zip,
    String country,
    String phone,
    String email,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainContact.copyWith(...)` or call `instanceOfDomainContact.copyWith.fieldName(value)` for a single field.
class _$DomainContactCWProxyImpl implements _$DomainContactCWProxy {
  const _$DomainContactCWProxyImpl(this._value);

  final DomainContact _value;

  @override
  DomainContact firstName(String firstName) => call(firstName: firstName);

  @override
  DomainContact lastName(String lastName) => call(lastName: lastName);

  @override
  DomainContact organization(String? organization) =>
      call(organization: organization);

  @override
  DomainContact address1(String address1) => call(address1: address1);

  @override
  DomainContact address2(String? address2) => call(address2: address2);

  @override
  DomainContact city(String city) => call(city: city);

  @override
  DomainContact state(String state) => call(state: state);

  @override
  DomainContact zip(String zip) => call(zip: zip);

  @override
  DomainContact country(String country) => call(country: country);

  @override
  DomainContact phone(String phone) => call(phone: phone);

  @override
  DomainContact email(String email) => call(email: email);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainContact(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainContact(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainContact call({
    Object? firstName = const $CopyWithPlaceholder(),
    Object? lastName = const $CopyWithPlaceholder(),
    Object? organization = const $CopyWithPlaceholder(),
    Object? address1 = const $CopyWithPlaceholder(),
    Object? address2 = const $CopyWithPlaceholder(),
    Object? city = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? zip = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
  }) {
    return DomainContact(
      firstName: firstName == const $CopyWithPlaceholder() || firstName == null
          ? _value.firstName
          // ignore: cast_nullable_to_non_nullable
          : firstName as String,
      lastName: lastName == const $CopyWithPlaceholder() || lastName == null
          ? _value.lastName
          // ignore: cast_nullable_to_non_nullable
          : lastName as String,
      organization: organization == const $CopyWithPlaceholder()
          ? _value.organization
          // ignore: cast_nullable_to_non_nullable
          : organization as String?,
      address1: address1 == const $CopyWithPlaceholder() || address1 == null
          ? _value.address1
          // ignore: cast_nullable_to_non_nullable
          : address1 as String,
      address2: address2 == const $CopyWithPlaceholder()
          ? _value.address2
          // ignore: cast_nullable_to_non_nullable
          : address2 as String?,
      city: city == const $CopyWithPlaceholder() || city == null
          ? _value.city
          // ignore: cast_nullable_to_non_nullable
          : city as String,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as String,
      zip: zip == const $CopyWithPlaceholder() || zip == null
          ? _value.zip
          // ignore: cast_nullable_to_non_nullable
          : zip as String,
      country: country == const $CopyWithPlaceholder() || country == null
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String,
      phone: phone == const $CopyWithPlaceholder() || phone == null
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
    );
  }
}

extension $DomainContactCopyWith on DomainContact {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainContact.copyWith(...)` or `instanceOfDomainContact.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainContactCWProxy get copyWith => _$DomainContactCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainContact _$DomainContactFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DomainContact', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'first_name',
          'last_name',
          'address1',
          'city',
          'state',
          'zip',
          'country',
          'phone',
          'email',
        ],
      );
      final val = DomainContact(
        firstName: $checkedConvert('first_name', (v) => v as String),
        lastName: $checkedConvert('last_name', (v) => v as String),
        organization: $checkedConvert('organization', (v) => v as String?),
        address1: $checkedConvert('address1', (v) => v as String),
        address2: $checkedConvert('address2', (v) => v as String?),
        city: $checkedConvert('city', (v) => v as String),
        state: $checkedConvert('state', (v) => v as String),
        zip: $checkedConvert('zip', (v) => v as String),
        country: $checkedConvert('country', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'firstName': 'first_name', 'lastName': 'last_name'});

Map<String, dynamic> _$DomainContactToJson(DomainContact instance) =>
    <String, dynamic>{
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'organization': ?instance.organization,
      'address1': instance.address1,
      'address2': ?instance.address2,
      'city': instance.city,
      'state': instance.state,
      'zip': instance.zip,
      'country': instance.country,
      'phone': instance.phone,
      'email': instance.email,
    };
