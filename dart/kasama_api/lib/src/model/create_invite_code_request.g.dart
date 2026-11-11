// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invite_code_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateInviteCodeRequestCWProxy {
  CreateInviteCodeRequest role(CreateInviteCodeRequestRoleEnum? role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateInviteCodeRequest call({CreateInviteCodeRequestRoleEnum? role});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateInviteCodeRequest.copyWith(...)` or call `instanceOfCreateInviteCodeRequest.copyWith.fieldName(value)` for a single field.
class _$CreateInviteCodeRequestCWProxyImpl
    implements _$CreateInviteCodeRequestCWProxy {
  const _$CreateInviteCodeRequestCWProxyImpl(this._value);

  final CreateInviteCodeRequest _value;

  @override
  CreateInviteCodeRequest role(CreateInviteCodeRequestRoleEnum? role) =>
      call(role: role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateInviteCodeRequest call({Object? role = const $CopyWithPlaceholder()}) {
    return CreateInviteCodeRequest(
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as CreateInviteCodeRequestRoleEnum?,
    );
  }
}

extension $CreateInviteCodeRequestCopyWith on CreateInviteCodeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateInviteCodeRequest.copyWith(...)` or `instanceOfCreateInviteCodeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateInviteCodeRequestCWProxy get copyWith =>
      _$CreateInviteCodeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateInviteCodeRequest _$CreateInviteCodeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateInviteCodeRequest', json, ($checkedConvert) {
  final val = CreateInviteCodeRequest(
    role: $checkedConvert(
      'role',
      (v) => $enumDecodeNullable(_$CreateInviteCodeRequestRoleEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$CreateInviteCodeRequestToJson(
  CreateInviteCodeRequest instance,
) => <String, dynamic>{
  'role': ?_$CreateInviteCodeRequestRoleEnumEnumMap[instance.role],
};

const _$CreateInviteCodeRequestRoleEnumEnumMap = {
  CreateInviteCodeRequestRoleEnum.admin: 'admin',
  CreateInviteCodeRequestRoleEnum.member: 'member',
};
