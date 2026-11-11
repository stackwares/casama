// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_invite_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedInviteLinkCWProxy {
  CreatedInviteLink id(String id);

  CreatedInviteLink orgId(String orgId);

  CreatedInviteLink role(CreatedInviteLinkRoleEnum role);

  CreatedInviteLink tokenHint(String tokenHint);

  CreatedInviteLink expiresAt(DateTime? expiresAt);

  CreatedInviteLink maxUses(int? maxUses);

  CreatedInviteLink uses(int uses);

  CreatedInviteLink revokedAt(DateTime? revokedAt);

  CreatedInviteLink createdAt(DateTime createdAt);

  CreatedInviteLink kind(CreatedInviteLinkKindEnum? kind);

  CreatedInviteLink requiresApproval(bool? requiresApproval);

  CreatedInviteLink isDefault(bool? isDefault);

  CreatedInviteLink token(String token);

  CreatedInviteLink url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedInviteLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedInviteLink(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedInviteLink call({
    String id,
    String orgId,
    CreatedInviteLinkRoleEnum role,
    String tokenHint,
    DateTime? expiresAt,
    int? maxUses,
    int uses,
    DateTime? revokedAt,
    DateTime createdAt,
    CreatedInviteLinkKindEnum? kind,
    bool? requiresApproval,
    bool? isDefault,
    String token,
    String url,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedInviteLink.copyWith(...)` or call `instanceOfCreatedInviteLink.copyWith.fieldName(value)` for a single field.
class _$CreatedInviteLinkCWProxyImpl implements _$CreatedInviteLinkCWProxy {
  const _$CreatedInviteLinkCWProxyImpl(this._value);

  final CreatedInviteLink _value;

  @override
  CreatedInviteLink id(String id) => call(id: id);

  @override
  CreatedInviteLink orgId(String orgId) => call(orgId: orgId);

  @override
  CreatedInviteLink role(CreatedInviteLinkRoleEnum role) => call(role: role);

  @override
  CreatedInviteLink tokenHint(String tokenHint) => call(tokenHint: tokenHint);

  @override
  CreatedInviteLink expiresAt(DateTime? expiresAt) =>
      call(expiresAt: expiresAt);

  @override
  CreatedInviteLink maxUses(int? maxUses) => call(maxUses: maxUses);

  @override
  CreatedInviteLink uses(int uses) => call(uses: uses);

  @override
  CreatedInviteLink revokedAt(DateTime? revokedAt) =>
      call(revokedAt: revokedAt);

  @override
  CreatedInviteLink createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedInviteLink kind(CreatedInviteLinkKindEnum? kind) => call(kind: kind);

  @override
  CreatedInviteLink requiresApproval(bool? requiresApproval) =>
      call(requiresApproval: requiresApproval);

  @override
  CreatedInviteLink isDefault(bool? isDefault) => call(isDefault: isDefault);

  @override
  CreatedInviteLink token(String token) => call(token: token);

  @override
  CreatedInviteLink url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedInviteLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedInviteLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedInviteLink call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? tokenHint = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? maxUses = const $CopyWithPlaceholder(),
    Object? uses = const $CopyWithPlaceholder(),
    Object? revokedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? requiresApproval = const $CopyWithPlaceholder(),
    Object? isDefault = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return CreatedInviteLink(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as CreatedInviteLinkRoleEnum,
      tokenHint: tokenHint == const $CopyWithPlaceholder() || tokenHint == null
          ? _value.tokenHint
          // ignore: cast_nullable_to_non_nullable
          : tokenHint as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      maxUses: maxUses == const $CopyWithPlaceholder()
          ? _value.maxUses
          // ignore: cast_nullable_to_non_nullable
          : maxUses as int?,
      uses: uses == const $CopyWithPlaceholder() || uses == null
          ? _value.uses
          // ignore: cast_nullable_to_non_nullable
          : uses as int,
      revokedAt: revokedAt == const $CopyWithPlaceholder()
          ? _value.revokedAt
          // ignore: cast_nullable_to_non_nullable
          : revokedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as CreatedInviteLinkKindEnum?,
      requiresApproval: requiresApproval == const $CopyWithPlaceholder()
          ? _value.requiresApproval
          // ignore: cast_nullable_to_non_nullable
          : requiresApproval as bool?,
      isDefault: isDefault == const $CopyWithPlaceholder()
          ? _value.isDefault
          // ignore: cast_nullable_to_non_nullable
          : isDefault as bool?,
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $CreatedInviteLinkCopyWith on CreatedInviteLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedInviteLink.copyWith(...)` or `instanceOfCreatedInviteLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedInviteLinkCWProxy get copyWith =>
      _$CreatedInviteLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedInviteLink _$CreatedInviteLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedInviteLink',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'org_id',
            'role',
            'token_hint',
            'expires_at',
            'max_uses',
            'uses',
            'revoked_at',
            'created_at',
            'token',
            'url',
          ],
        );
        final val = CreatedInviteLink(
          id: $checkedConvert('id', (v) => v as String),
          orgId: $checkedConvert('org_id', (v) => v as String),
          role: $checkedConvert(
            'role',
            (v) => $enumDecode(_$CreatedInviteLinkRoleEnumEnumMap, v),
          ),
          tokenHint: $checkedConvert('token_hint', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          maxUses: $checkedConvert('max_uses', (v) => (v as num?)?.toInt()),
          uses: $checkedConvert('uses', (v) => (v as num).toInt()),
          revokedAt: $checkedConvert(
            'revoked_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecodeNullable(_$CreatedInviteLinkKindEnumEnumMap, v),
          ),
          requiresApproval: $checkedConvert(
            'requires_approval',
            (v) => v as bool?,
          ),
          isDefault: $checkedConvert('is_default', (v) => v as bool?),
          token: $checkedConvert('token', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'tokenHint': 'token_hint',
        'expiresAt': 'expires_at',
        'maxUses': 'max_uses',
        'revokedAt': 'revoked_at',
        'createdAt': 'created_at',
        'requiresApproval': 'requires_approval',
        'isDefault': 'is_default',
      },
    );

Map<String, dynamic> _$CreatedInviteLinkToJson(CreatedInviteLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'role': _$CreatedInviteLinkRoleEnumEnumMap[instance.role]!,
      'token_hint': instance.tokenHint,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'max_uses': instance.maxUses,
      'uses': instance.uses,
      'revoked_at': instance.revokedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'kind': ?_$CreatedInviteLinkKindEnumEnumMap[instance.kind],
      'requires_approval': ?instance.requiresApproval,
      'is_default': ?instance.isDefault,
      'token': instance.token,
      'url': instance.url,
    };

const _$CreatedInviteLinkRoleEnumEnumMap = {
  CreatedInviteLinkRoleEnum.admin: 'admin',
  CreatedInviteLinkRoleEnum.member: 'member',
};

const _$CreatedInviteLinkKindEnumEnumMap = {
  CreatedInviteLinkKindEnum.link: 'link',
  CreatedInviteLinkKindEnum.code: 'code',
};
