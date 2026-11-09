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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Invite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInvite.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInvite.copyWith.fieldName(...)`
class _$InviteCWProxyImpl implements _$InviteCWProxy {
  const _$InviteCWProxyImpl(this._value);

  final Invite _value;

  @override
  Invite id(String id) => this(id: id);

  @override
  Invite orgId(String orgId) => this(orgId: orgId);

  @override
  Invite email(String email) => this(email: email);

  @override
  Invite role(OrgRole role) => this(role: role);

  @override
  Invite expiresAt(DateTime expiresAt) => this(expiresAt: expiresAt);

  @override
  Invite emailSent(bool emailSent) => this(emailSent: emailSent);

  @override
  Invite acceptToken(String? acceptToken) => this(acceptToken: acceptToken);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Invite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ````
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
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as OrgRole,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      emailSent: emailSent == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfInvite.copyWith(...)` or like so:`instanceOfInvite.copyWith.fieldName(...)`.
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
