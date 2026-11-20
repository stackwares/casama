// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_admin_pin_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetAdminPinRequestCWProxy {
  SetAdminPinRequest pin(String pin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetAdminPinRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetAdminPinRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetAdminPinRequest call({String pin});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetAdminPinRequest.copyWith(...)` or call `instanceOfSetAdminPinRequest.copyWith.fieldName(value)` for a single field.
class _$SetAdminPinRequestCWProxyImpl implements _$SetAdminPinRequestCWProxy {
  const _$SetAdminPinRequestCWProxyImpl(this._value);

  final SetAdminPinRequest _value;

  @override
  SetAdminPinRequest pin(String pin) => call(pin: pin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetAdminPinRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetAdminPinRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetAdminPinRequest call({Object? pin = const $CopyWithPlaceholder()}) {
    return SetAdminPinRequest(
      pin: pin == const $CopyWithPlaceholder() || pin == null
          ? _value.pin
          // ignore: cast_nullable_to_non_nullable
          : pin as String,
    );
  }
}

extension $SetAdminPinRequestCopyWith on SetAdminPinRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetAdminPinRequest.copyWith(...)` or `instanceOfSetAdminPinRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetAdminPinRequestCWProxy get copyWith =>
      _$SetAdminPinRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetAdminPinRequest _$SetAdminPinRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetAdminPinRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['pin']);
      final val = SetAdminPinRequest(
        pin: $checkedConvert('pin', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SetAdminPinRequestToJson(SetAdminPinRequest instance) =>
    <String, dynamic>{'pin': instance.pin};
