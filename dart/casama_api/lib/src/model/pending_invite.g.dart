// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_invite.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PendingInviteCWProxy {
  PendingInvite id(String id);

  PendingInvite email(String email);

  PendingInvite role(PendingInviteRoleEnum role);

  PendingInvite expiresAt(DateTime expiresAt);

  PendingInvite createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PendingInvite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PendingInvite(...).copyWith(id: 12, name: "My name")
  /// ```
  PendingInvite call({
    String id,
    String email,
    PendingInviteRoleEnum role,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPendingInvite.copyWith(...)` or call `instanceOfPendingInvite.copyWith.fieldName(value)` for a single field.
class _$PendingInviteCWProxyImpl implements _$PendingInviteCWProxy {
  const _$PendingInviteCWProxyImpl(this._value);

  final PendingInvite _value;

  @override
  PendingInvite id(String id) => call(id: id);

  @override
  PendingInvite email(String email) => call(email: email);

  @override
  PendingInvite role(PendingInviteRoleEnum role) => call(role: role);

  @override
  PendingInvite expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  PendingInvite createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PendingInvite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PendingInvite(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PendingInvite call({
    Object? id = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return PendingInvite(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as PendingInviteRoleEnum,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $PendingInviteCopyWith on PendingInvite {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPendingInvite.copyWith(...)` or `instanceOfPendingInvite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PendingInviteCWProxy get copyWith => _$PendingInviteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingInvite _$PendingInviteFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PendingInvite', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'email', 'role', 'expires_at', 'created_at'],
  );
  final val = PendingInvite(
    id: $checkedConvert('id', (v) => v as String),
    email: $checkedConvert('email', (v) => v as String),
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(_$PendingInviteRoleEnumEnumMap, v),
    ),
    expiresAt: $checkedConvert(
      'expires_at',
      (v) => DateTime.parse(v as String),
    ),
    createdAt: $checkedConvert(
      'created_at',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'expiresAt': 'expires_at', 'createdAt': 'created_at'});

Map<String, dynamic> _$PendingInviteToJson(PendingInvite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'role': _$PendingInviteRoleEnumEnumMap[instance.role]!,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PendingInviteRoleEnumEnumMap = {
  PendingInviteRoleEnum.owner: 'owner',
  PendingInviteRoleEnum.admin: 'admin',
  PendingInviteRoleEnum.member: 'member',
};
