// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invites_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateInvitesRequestCWProxy {
  CreateInvitesRequest emails(List<String> emails);

  CreateInvitesRequest role(CreateInvitesRequestRoleEnum? role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInvitesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInvitesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateInvitesRequest call({
    List<String> emails,
    CreateInvitesRequestRoleEnum? role,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateInvitesRequest.copyWith(...)` or call `instanceOfCreateInvitesRequest.copyWith.fieldName(value)` for a single field.
class _$CreateInvitesRequestCWProxyImpl
    implements _$CreateInvitesRequestCWProxy {
  const _$CreateInvitesRequestCWProxyImpl(this._value);

  final CreateInvitesRequest _value;

  @override
  CreateInvitesRequest emails(List<String> emails) => call(emails: emails);

  @override
  CreateInvitesRequest role(CreateInvitesRequestRoleEnum? role) =>
      call(role: role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInvitesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInvitesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateInvitesRequest call({
    Object? emails = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return CreateInvitesRequest(
      emails: emails == const $CopyWithPlaceholder() || emails == null
          ? _value.emails
          // ignore: cast_nullable_to_non_nullable
          : emails as List<String>,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as CreateInvitesRequestRoleEnum?,
    );
  }
}

extension $CreateInvitesRequestCopyWith on CreateInvitesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateInvitesRequest.copyWith(...)` or `instanceOfCreateInvitesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateInvitesRequestCWProxy get copyWith =>
      _$CreateInvitesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateInvitesRequest _$CreateInvitesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateInvitesRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['emails']);
  final val = CreateInvitesRequest(
    emails: $checkedConvert(
      'emails',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    role: $checkedConvert(
      'role',
      (v) => $enumDecodeNullable(_$CreateInvitesRequestRoleEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$CreateInvitesRequestToJson(
  CreateInvitesRequest instance,
) => <String, dynamic>{
  'emails': instance.emails,
  'role': ?_$CreateInvitesRequestRoleEnumEnumMap[instance.role],
};

const _$CreateInvitesRequestRoleEnumEnumMap = {
  CreateInvitesRequestRoleEnum.admin: 'admin',
  CreateInvitesRequestRoleEnum.member: 'member',
};
