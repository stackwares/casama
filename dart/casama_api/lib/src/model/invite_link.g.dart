// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteLinkCWProxy {
  InviteLink id(String id);

  InviteLink orgId(String orgId);

  InviteLink role(InviteLinkRoleEnum role);

  InviteLink tokenHint(String tokenHint);

  InviteLink expiresAt(DateTime? expiresAt);

  InviteLink maxUses(int? maxUses);

  InviteLink uses(int uses);

  InviteLink revokedAt(DateTime? revokedAt);

  InviteLink createdAt(DateTime createdAt);

  InviteLink kind(InviteLinkKindEnum? kind);

  InviteLink requiresApproval(bool? requiresApproval);

  InviteLink isDefault(bool? isDefault);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteLink(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteLink call({
    String id,
    String orgId,
    InviteLinkRoleEnum role,
    String tokenHint,
    DateTime? expiresAt,
    int? maxUses,
    int uses,
    DateTime? revokedAt,
    DateTime createdAt,
    InviteLinkKindEnum? kind,
    bool? requiresApproval,
    bool? isDefault,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteLink.copyWith(...)` or call `instanceOfInviteLink.copyWith.fieldName(value)` for a single field.
class _$InviteLinkCWProxyImpl implements _$InviteLinkCWProxy {
  const _$InviteLinkCWProxyImpl(this._value);

  final InviteLink _value;

  @override
  InviteLink id(String id) => call(id: id);

  @override
  InviteLink orgId(String orgId) => call(orgId: orgId);

  @override
  InviteLink role(InviteLinkRoleEnum role) => call(role: role);

  @override
  InviteLink tokenHint(String tokenHint) => call(tokenHint: tokenHint);

  @override
  InviteLink expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  InviteLink maxUses(int? maxUses) => call(maxUses: maxUses);

  @override
  InviteLink uses(int uses) => call(uses: uses);

  @override
  InviteLink revokedAt(DateTime? revokedAt) => call(revokedAt: revokedAt);

  @override
  InviteLink createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  InviteLink kind(InviteLinkKindEnum? kind) => call(kind: kind);

  @override
  InviteLink requiresApproval(bool? requiresApproval) =>
      call(requiresApproval: requiresApproval);

  @override
  InviteLink isDefault(bool? isDefault) => call(isDefault: isDefault);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteLink call({
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
  }) {
    return InviteLink(
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
          : role as InviteLinkRoleEnum,
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
          : kind as InviteLinkKindEnum?,
      requiresApproval: requiresApproval == const $CopyWithPlaceholder()
          ? _value.requiresApproval
          // ignore: cast_nullable_to_non_nullable
          : requiresApproval as bool?,
      isDefault: isDefault == const $CopyWithPlaceholder()
          ? _value.isDefault
          // ignore: cast_nullable_to_non_nullable
          : isDefault as bool?,
    );
  }
}

extension $InviteLinkCopyWith on InviteLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteLink.copyWith(...)` or `instanceOfInviteLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteLinkCWProxy get copyWith => _$InviteLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteLink _$InviteLinkFromJson(Map<String, dynamic> json) => $checkedCreate(
  'InviteLink',
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
      ],
    );
    final val = InviteLink(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(_$InviteLinkRoleEnumEnumMap, v),
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
        (v) => $enumDecodeNullable(_$InviteLinkKindEnumEnumMap, v),
      ),
      requiresApproval: $checkedConvert('requires_approval', (v) => v as bool?),
      isDefault: $checkedConvert('is_default', (v) => v as bool?),
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

Map<String, dynamic> _$InviteLinkToJson(InviteLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'role': _$InviteLinkRoleEnumEnumMap[instance.role]!,
      'token_hint': instance.tokenHint,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'max_uses': instance.maxUses,
      'uses': instance.uses,
      'revoked_at': instance.revokedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'kind': ?_$InviteLinkKindEnumEnumMap[instance.kind],
      'requires_approval': ?instance.requiresApproval,
      'is_default': ?instance.isDefault,
    };

const _$InviteLinkRoleEnumEnumMap = {
  InviteLinkRoleEnum.admin: 'admin',
  InviteLinkRoleEnum.member: 'member',
};

const _$InviteLinkKindEnumEnumMap = {
  InviteLinkKindEnum.link: 'link',
  InviteLinkKindEnum.code: 'code',
};
