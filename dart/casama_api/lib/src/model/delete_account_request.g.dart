// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteAccountRequestCWProxy {
  DeleteAccountRequest confirmEmail(String confirmEmail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteAccountRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteAccountRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DeleteAccountRequest call({String confirmEmail});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeleteAccountRequest.copyWith(...)` or call `instanceOfDeleteAccountRequest.copyWith.fieldName(value)` for a single field.
class _$DeleteAccountRequestCWProxyImpl
    implements _$DeleteAccountRequestCWProxy {
  const _$DeleteAccountRequestCWProxyImpl(this._value);

  final DeleteAccountRequest _value;

  @override
  DeleteAccountRequest confirmEmail(String confirmEmail) =>
      call(confirmEmail: confirmEmail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteAccountRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteAccountRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeleteAccountRequest call({
    Object? confirmEmail = const $CopyWithPlaceholder(),
  }) {
    return DeleteAccountRequest(
      confirmEmail:
          confirmEmail == const $CopyWithPlaceholder() || confirmEmail == null
          ? _value.confirmEmail
          // ignore: cast_nullable_to_non_nullable
          : confirmEmail as String,
    );
  }
}

extension $DeleteAccountRequestCopyWith on DeleteAccountRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeleteAccountRequest.copyWith(...)` or `instanceOfDeleteAccountRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteAccountRequestCWProxy get copyWith =>
      _$DeleteAccountRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteAccountRequest _$DeleteAccountRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeleteAccountRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['confirm_email']);
  final val = DeleteAccountRequest(
    confirmEmail: $checkedConvert('confirm_email', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'confirmEmail': 'confirm_email'});

Map<String, dynamic> _$DeleteAccountRequestToJson(
  DeleteAccountRequest instance,
) => <String, dynamic>{'confirm_email': instance.confirmEmail};
