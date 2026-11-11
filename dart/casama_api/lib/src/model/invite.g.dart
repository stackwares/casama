// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCWProxy {
  Invite id(String id);

  Invite orgId(String orgId);

  Invite email(String email);

  Invite role(OrgRole role);

  Invite expiresAt(DateTime expiresAt);

  Invite emailSent(bool emailSent);

  Invite acceptToken(String? acceptToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Invite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ```
  Invite call({
    String id,
    String orgId,
    String email,
    OrgRole role,
    DateTime expiresAt,
    bool emailSent,
    String? acceptToken,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInvite.copyWith(...)` or call `instanceOfInvite.copyWith.fieldName(value)` for a single field.
class _$InviteCWProxyImpl implements _$InviteCWProxy {
  const _$InviteCWProxyImpl(this._value);

  final Invite _value;

  @override
  Invite id(String id) => call(id: id);

  @override
  Invite orgId(String orgId) => call(orgId: orgId);

  @override
  Invite email(String email) => call(email: email);

  @override
  Invite role(OrgRole role) => call(role: role);

  @override
  Invite expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  Invite emailSent(bool emailSent) => call(emailSent: emailSent);

  @override
  Invite acceptToken(String? acceptToken) => call(acceptToken: acceptToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Invite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Invite call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? emailSent = const $CopyWithPlaceholder(),
    Object? acceptToken = const $CopyWithPlaceholder(),
  }) {
    return Invite(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OrgRole,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      emailSent: emailSent == const $CopyWithPlaceholder() || emailSent == null
          ? _value.emailSent
          // ignore: cast_nullable_to_non_nullable
          : emailSent as bool,
      acceptToken: acceptToken == const $CopyWithPlaceholder()
          ? _value.acceptToken
          // ignore: cast_nullable_to_non_nullable
          : acceptToken as String?,
    );
  }
}

extension $InviteCopyWith on Invite {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInvite.copyWith(...)` or `instanceOfInvite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCWProxy get copyWith => _$InviteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invite _$InviteFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Invite',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'email',
        'role',
        'expires_at',
        'email_sent',
      ],
    );
    final val = Invite(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      role: $checkedConvert('role', (v) => $enumDecode(_$OrgRoleEnumMap, v)),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      emailSent: $checkedConvert('email_sent', (v) => v as bool),
      acceptToken: $checkedConvert('accept_token', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'expiresAt': 'expires_at',
    'emailSent': 'email_sent',
    'acceptToken': 'accept_token',
  },
);

Map<String, dynamic> _$InviteToJson(Invite instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'email': instance.email,
  'role': _$OrgRoleEnumMap[instance.role]!,
  'expires_at': instance.expiresAt.toIso8601String(),
  'email_sent': instance.emailSent,
  'accept_token': ?instance.acceptToken,
};

const _$OrgRoleEnumMap = {
  OrgRole.owner: 'owner',
  OrgRole.admin: 'admin',
  OrgRole.member: 'member',
};
