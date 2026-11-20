// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_passkey_check_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPasskeyCheckRequestCWProxy {
  AdminPasskeyCheckRequest token(String token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPasskeyCheckRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPasskeyCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPasskeyCheckRequest call({String token});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPasskeyCheckRequest.copyWith(...)` or call `instanceOfAdminPasskeyCheckRequest.copyWith.fieldName(value)` for a single field.
class _$AdminPasskeyCheckRequestCWProxyImpl
    implements _$AdminPasskeyCheckRequestCWProxy {
  const _$AdminPasskeyCheckRequestCWProxyImpl(this._value);

  final AdminPasskeyCheckRequest _value;

  @override
  AdminPasskeyCheckRequest token(String token) => call(token: token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPasskeyCheckRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPasskeyCheckRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPasskeyCheckRequest call({
    Object? token = const $CopyWithPlaceholder(),
  }) {
    return AdminPasskeyCheckRequest(
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
    );
  }
}

extension $AdminPasskeyCheckRequestCopyWith on AdminPasskeyCheckRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPasskeyCheckRequest.copyWith(...)` or `instanceOfAdminPasskeyCheckRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPasskeyCheckRequestCWProxy get copyWith =>
      _$AdminPasskeyCheckRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPasskeyCheckRequest _$AdminPasskeyCheckRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminPasskeyCheckRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['token']);
  final val = AdminPasskeyCheckRequest(
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AdminPasskeyCheckRequestToJson(
  AdminPasskeyCheckRequest instance,
) => <String, dynamic>{'token': instance.token};
