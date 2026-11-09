// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invite_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateInviteRequestCWProxy {
  CreateInviteRequest email(String email);

  CreateInviteRequest role(InviteRole? role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateInviteRequest call({String email, InviteRole? role});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateInviteRequest.copyWith(...)` or call `instanceOfCreateInviteRequest.copyWith.fieldName(value)` for a single field.
class _$CreateInviteRequestCWProxyImpl implements _$CreateInviteRequestCWProxy {
  const _$CreateInviteRequestCWProxyImpl(this._value);

  final CreateInviteRequest _value;

  @override
  CreateInviteRequest email(String email) => call(email: email);

  @override
  CreateInviteRequest role(InviteRole? role) => call(role: role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateInviteRequest call({
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return CreateInviteRequest(
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as InviteRole?,
    );
  }
}

extension $CreateInviteRequestCopyWith on CreateInviteRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateInviteRequest.copyWith(...)` or `instanceOfCreateInviteRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateInviteRequestCWProxy get copyWith =>
      _$CreateInviteRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateInviteRequest _$CreateInviteRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateInviteRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['email']);
      final val = CreateInviteRequest(
        email: $checkedConvert('email', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecodeNullable(_$InviteRoleEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateInviteRequestToJson(
  CreateInviteRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'role': ?_$InviteRoleEnumMap[instance.role],
};

const _$InviteRoleEnumMap = {
  InviteRole.admin: 'admin',
  InviteRole.member: 'member',
};
