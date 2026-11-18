// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_contact_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainContactStateCWProxy {
  DomainContactState contact(DomainContact? contact);

  DomainContactState defaultEmail(String? defaultEmail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainContactState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainContactState(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainContactState call({DomainContact? contact, String? defaultEmail});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainContactState.copyWith(...)` or call `instanceOfDomainContactState.copyWith.fieldName(value)` for a single field.
class _$DomainContactStateCWProxyImpl implements _$DomainContactStateCWProxy {
  const _$DomainContactStateCWProxyImpl(this._value);

  final DomainContactState _value;

  @override
  DomainContactState contact(DomainContact? contact) => call(contact: contact);

  @override
  DomainContactState defaultEmail(String? defaultEmail) =>
      call(defaultEmail: defaultEmail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainContactState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainContactState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainContactState call({
    Object? contact = const $CopyWithPlaceholder(),
    Object? defaultEmail = const $CopyWithPlaceholder(),
  }) {
    return DomainContactState(
      contact: contact == const $CopyWithPlaceholder()
          ? _value.contact
          // ignore: cast_nullable_to_non_nullable
          : contact as DomainContact?,
      defaultEmail: defaultEmail == const $CopyWithPlaceholder()
          ? _value.defaultEmail
          // ignore: cast_nullable_to_non_nullable
          : defaultEmail as String?,
    );
  }
}

extension $DomainContactStateCopyWith on DomainContactState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainContactState.copyWith(...)` or `instanceOfDomainContactState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainContactStateCWProxy get copyWith =>
      _$DomainContactStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainContactState _$DomainContactStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DomainContactState', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['contact', 'default_email']);
      final val = DomainContactState(
        contact: $checkedConvert(
          'contact',
          (v) => v == null
              ? null
              : DomainContact.fromJson(v as Map<String, dynamic>),
        ),
        defaultEmail: $checkedConvert('default_email', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'defaultEmail': 'default_email'});

Map<String, dynamic> _$DomainContactStateToJson(DomainContactState instance) =>
    <String, dynamic>{
      'contact': instance.contact?.toJson(),
      'default_email': instance.defaultEmail,
    };
