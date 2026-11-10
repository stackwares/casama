// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_member.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceMemberCWProxy {
  WorkspaceMember userId(String userId);

  WorkspaceMember email(String? email);

  WorkspaceMember role(WorkspaceMemberRoleEnum role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceMember(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceMember(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceMember call({
    String userId,
    String? email,
    WorkspaceMemberRoleEnum role,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceMember.copyWith(...)` or call `instanceOfWorkspaceMember.copyWith.fieldName(value)` for a single field.
class _$WorkspaceMemberCWProxyImpl implements _$WorkspaceMemberCWProxy {
  const _$WorkspaceMemberCWProxyImpl(this._value);

  final WorkspaceMember _value;

  @override
  WorkspaceMember userId(String userId) => call(userId: userId);

  @override
  WorkspaceMember email(String? email) => call(email: email);

  @override
  WorkspaceMember role(WorkspaceMemberRoleEnum role) => call(role: role);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceMember(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceMember(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceMember call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
  }) {
    return WorkspaceMember(
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as WorkspaceMemberRoleEnum,
    );
  }
}

extension $WorkspaceMemberCopyWith on WorkspaceMember {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceMember.copyWith(...)` or `instanceOfWorkspaceMember.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceMemberCWProxy get copyWith => _$WorkspaceMemberCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceMember _$WorkspaceMemberFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WorkspaceMember', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user_id', 'email', 'role']);
      final val = WorkspaceMember(
        userId: $checkedConvert('user_id', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String?),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$WorkspaceMemberRoleEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id'});

Map<String, dynamic> _$WorkspaceMemberToJson(WorkspaceMember instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'role': _$WorkspaceMemberRoleEnumEnumMap[instance.role]!,
    };

const _$WorkspaceMemberRoleEnumEnumMap = {
  WorkspaceMemberRoleEnum.owner: 'owner',
  WorkspaceMemberRoleEnum.admin: 'admin',
  WorkspaceMemberRoleEnum.member: 'member',
};
