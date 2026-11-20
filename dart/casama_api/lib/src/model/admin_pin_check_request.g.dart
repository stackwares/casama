// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_pin_check_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPinCheckRequestCWProxy {
  AdminPinCheckRequest pin(String pin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPinCheckRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPinCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPinCheckRequest call({String pin});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPinCheckRequest.copyWith(...)` or call `instanceOfAdminPinCheckRequest.copyWith.fieldName(value)` for a single field.
class _$AdminPinCheckRequestCWProxyImpl
    implements _$AdminPinCheckRequestCWProxy {
  const _$AdminPinCheckRequestCWProxyImpl(this._value);

  final AdminPinCheckRequest _value;

  @override
  AdminPinCheckRequest pin(String pin) => call(pin: pin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPinCheckRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPinCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPinCheckRequest call({Object? pin = const $CopyWithPlaceholder()}) {
    return AdminPinCheckRequest(
      pin: pin == const $CopyWithPlaceholder() || pin == null
          ? _value.pin
          // ignore: cast_nullable_to_non_nullable
          : pin as String,
    );
  }
}

extension $AdminPinCheckRequestCopyWith on AdminPinCheckRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPinCheckRequest.copyWith(...)` or `instanceOfAdminPinCheckRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPinCheckRequestCWProxy get copyWith =>
      _$AdminPinCheckRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPinCheckRequest _$AdminPinCheckRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminPinCheckRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['pin']);
  final val = AdminPinCheckRequest(
    pin: $checkedConvert('pin', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AdminPinCheckRequestToJson(
  AdminPinCheckRequest instance,
) => <String, dynamic>{'pin': instance.pin};
