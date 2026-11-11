// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invite_link_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateInviteLinkRequestCWProxy {
  CreateInviteLinkRequest role(CreateInviteLinkRequestRoleEnum? role);

  CreateInviteLinkRequest expiresInDays(int? expiresInDays);

  CreateInviteLinkRequest maxUses(int? maxUses);

  CreateInviteLinkRequest requiresApproval(bool? requiresApproval);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateInviteLinkRequest call({
    CreateInviteLinkRequestRoleEnum? role,
    int? expiresInDays,
    int? maxUses,
    bool? requiresApproval,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateInviteLinkRequest.copyWith(...)` or call `instanceOfCreateInviteLinkRequest.copyWith.fieldName(value)` for a single field.
class _$CreateInviteLinkRequestCWProxyImpl
    implements _$CreateInviteLinkRequestCWProxy {
  const _$CreateInviteLinkRequestCWProxyImpl(this._value);

  final CreateInviteLinkRequest _value;

  @override
  CreateInviteLinkRequest role(CreateInviteLinkRequestRoleEnum? role) =>
      call(role: role);

  @override
  CreateInviteLinkRequest expiresInDays(int? expiresInDays) =>
      call(expiresInDays: expiresInDays);

  @override
  CreateInviteLinkRequest maxUses(int? maxUses) => call(maxUses: maxUses);

  @override
  CreateInviteLinkRequest requiresApproval(bool? requiresApproval) =>
      call(requiresApproval: requiresApproval);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateInviteLinkRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateInviteLinkRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateInviteLinkRequest call({
    Object? role = const $CopyWithPlaceholder(),
    Object? expiresInDays = const $CopyWithPlaceholder(),
    Object? maxUses = const $CopyWithPlaceholder(),
    Object? requiresApproval = const $CopyWithPlaceholder(),
  }) {
    return CreateInviteLinkRequest(
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as CreateInviteLinkRequestRoleEnum?,
      expiresInDays: expiresInDays == const $CopyWithPlaceholder()
          ? _value.expiresInDays
          // ignore: cast_nullable_to_non_nullable
          : expiresInDays as int?,
      maxUses: maxUses == const $CopyWithPlaceholder()
          ? _value.maxUses
          // ignore: cast_nullable_to_non_nullable
          : maxUses as int?,
      requiresApproval: requiresApproval == const $CopyWithPlaceholder()
          ? _value.requiresApproval
          // ignore: cast_nullable_to_non_nullable
          : requiresApproval as bool?,
    );
  }
}

extension $CreateInviteLinkRequestCopyWith on CreateInviteLinkRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateInviteLinkRequest.copyWith(...)` or `instanceOfCreateInviteLinkRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateInviteLinkRequestCWProxy get copyWith =>
      _$CreateInviteLinkRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateInviteLinkRequest _$CreateInviteLinkRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateInviteLinkRequest',
  json,
  ($checkedConvert) {
    final val = CreateInviteLinkRequest(
      role: $checkedConvert(
        'role',
        (v) => $enumDecodeNullable(_$CreateInviteLinkRequestRoleEnumEnumMap, v),
      ),
      expiresInDays: $checkedConvert(
        'expires_in_days',
        (v) => (v as num?)?.toInt(),
      ),
      maxUses: $checkedConvert('max_uses', (v) => (v as num?)?.toInt()),
      requiresApproval: $checkedConvert('requires_approval', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'expiresInDays': 'expires_in_days',
    'maxUses': 'max_uses',
    'requiresApproval': 'requires_approval',
  },
);

Map<String, dynamic> _$CreateInviteLinkRequestToJson(
  CreateInviteLinkRequest instance,
) => <String, dynamic>{
  'role': ?_$CreateInviteLinkRequestRoleEnumEnumMap[instance.role],
  'expires_in_days': ?instance.expiresInDays,
  'max_uses': ?instance.maxUses,
  'requires_approval': ?instance.requiresApproval,
};

const _$CreateInviteLinkRequestRoleEnumEnumMap = {
  CreateInviteLinkRequestRoleEnum.admin: 'admin',
  CreateInviteLinkRequestRoleEnum.member: 'member',
};
