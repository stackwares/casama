// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$JoinRequestCWProxy {
  JoinRequest id(String id);

  JoinRequest orgId(String orgId);

  JoinRequest userId(String userId);

  JoinRequest email(String? email);

  JoinRequest displayName(String? displayName);

  JoinRequest role(JoinRequestRoleEnum role);

  JoinRequest status(JoinRequestStatusEnum status);

  JoinRequest createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  JoinRequest call({
    String id,
    String orgId,
    String userId,
    String? email,
    String? displayName,
    JoinRequestRoleEnum role,
    JoinRequestStatusEnum status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfJoinRequest.copyWith(...)` or call `instanceOfJoinRequest.copyWith.fieldName(value)` for a single field.
class _$JoinRequestCWProxyImpl implements _$JoinRequestCWProxy {
  const _$JoinRequestCWProxyImpl(this._value);

  final JoinRequest _value;

  @override
  JoinRequest id(String id) => call(id: id);

  @override
  JoinRequest orgId(String orgId) => call(orgId: orgId);

  @override
  JoinRequest userId(String userId) => call(userId: userId);

  @override
  JoinRequest email(String? email) => call(email: email);

  @override
  JoinRequest displayName(String? displayName) =>
      call(displayName: displayName);

  @override
  JoinRequest role(JoinRequestRoleEnum role) => call(role: role);

  @override
  JoinRequest status(JoinRequestStatusEnum status) => call(status: status);

  @override
  JoinRequest createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `JoinRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// JoinRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  JoinRequest call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return JoinRequest(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      role: role == const $CopyWithPlaceholder() || role == null
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as JoinRequestRoleEnum,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as JoinRequestStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $JoinRequestCopyWith on JoinRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfJoinRequest.copyWith(...)` or `instanceOfJoinRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$JoinRequestCWProxy get copyWith => _$JoinRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinRequest _$JoinRequestFromJson(Map<String, dynamic> json) => $checkedCreate(
  'JoinRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'user_id',
        'email',
        'display_name',
        'role',
        'status',
        'created_at',
      ],
    );
    final val = JoinRequest(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      userId: $checkedConvert('user_id', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String?),
      displayName: $checkedConvert('display_name', (v) => v as String?),
      role: $checkedConvert(
        'role',
        (v) => $enumDecode(_$JoinRequestRoleEnumEnumMap, v),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$JoinRequestStatusEnumEnumMap, v),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'userId': 'user_id',
    'displayName': 'display_name',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$JoinRequestToJson(JoinRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'user_id': instance.userId,
      'email': instance.email,
      'display_name': instance.displayName,
      'role': _$JoinRequestRoleEnumEnumMap[instance.role]!,
      'status': _$JoinRequestStatusEnumEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$JoinRequestRoleEnumEnumMap = {
  JoinRequestRoleEnum.admin: 'admin',
  JoinRequestRoleEnum.member: 'member',
};

const _$JoinRequestStatusEnumEnumMap = {
  JoinRequestStatusEnum.pending: 'pending',
  JoinRequestStatusEnum.approved: 'approved',
  JoinRequestStatusEnum.declined: 'declined',
};
