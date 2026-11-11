// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_bot_access_request_entries_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetBotAccessRequestEntriesInnerCWProxy {
  SetBotAccessRequestEntriesInner userId(String? userId);

  SetBotAccessRequestEntriesInner role(
    SetBotAccessRequestEntriesInnerRoleEnum? role,
  );

  SetBotAccessRequestEntriesInner access(
    SetBotAccessRequestEntriesInnerAccessEnum access,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotAccessRequestEntriesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotAccessRequestEntriesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  SetBotAccessRequestEntriesInner call({
    String? userId,
    SetBotAccessRequestEntriesInnerRoleEnum? role,
    SetBotAccessRequestEntriesInnerAccessEnum access,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetBotAccessRequestEntriesInner.copyWith(...)` or call `instanceOfSetBotAccessRequestEntriesInner.copyWith.fieldName(value)` for a single field.
class _$SetBotAccessRequestEntriesInnerCWProxyImpl
    implements _$SetBotAccessRequestEntriesInnerCWProxy {
  const _$SetBotAccessRequestEntriesInnerCWProxyImpl(this._value);

  final SetBotAccessRequestEntriesInner _value;

  @override
  SetBotAccessRequestEntriesInner userId(String? userId) =>
      call(userId: userId);

  @override
  SetBotAccessRequestEntriesInner role(
    SetBotAccessRequestEntriesInnerRoleEnum? role,
  ) => call(role: role);

  @override
  SetBotAccessRequestEntriesInner access(
    SetBotAccessRequestEntriesInnerAccessEnum access,
  ) => call(access: access);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetBotAccessRequestEntriesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetBotAccessRequestEntriesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetBotAccessRequestEntriesInner call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? access = const $CopyWithPlaceholder(),
  }) {
    return SetBotAccessRequestEntriesInner(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String?,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as SetBotAccessRequestEntriesInnerRoleEnum?,
      access: access == const $CopyWithPlaceholder() || access == null
          ? _value.access
          // ignore: cast_nullable_to_non_nullable
          : access as SetBotAccessRequestEntriesInnerAccessEnum,
    );
  }
}

extension $SetBotAccessRequestEntriesInnerCopyWith
    on SetBotAccessRequestEntriesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetBotAccessRequestEntriesInner.copyWith(...)` or `instanceOfSetBotAccessRequestEntriesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetBotAccessRequestEntriesInnerCWProxy get copyWith =>
      _$SetBotAccessRequestEntriesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetBotAccessRequestEntriesInner _$SetBotAccessRequestEntriesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetBotAccessRequestEntriesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['access']);
  final val = SetBotAccessRequestEntriesInner(
    userId: $checkedConvert('user_id', (v) => v as String?),
    role: $checkedConvert(
      'role',
      (v) => $enumDecodeNullable(
        _$SetBotAccessRequestEntriesInnerRoleEnumEnumMap,
        v,
      ),
    ),
    access: $checkedConvert(
      'access',
      (v) => $enumDecode(_$SetBotAccessRequestEntriesInnerAccessEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'userId': 'user_id'});

Map<String, dynamic> _$SetBotAccessRequestEntriesInnerToJson(
  SetBotAccessRequestEntriesInner instance,
) => <String, dynamic>{
  'user_id': ?instance.userId,
  'role': ?_$SetBotAccessRequestEntriesInnerRoleEnumEnumMap[instance.role],
  'access':
      _$SetBotAccessRequestEntriesInnerAccessEnumEnumMap[instance.access]!,
};

const _$SetBotAccessRequestEntriesInnerRoleEnumEnumMap = {
  SetBotAccessRequestEntriesInnerRoleEnum.owner: 'owner',
  SetBotAccessRequestEntriesInnerRoleEnum.admin: 'admin',
  SetBotAccessRequestEntriesInnerRoleEnum.member: 'member',
};

const _$SetBotAccessRequestEntriesInnerAccessEnumEnumMap = {
  SetBotAccessRequestEntriesInnerAccessEnum.chat: 'chat',
  SetBotAccessRequestEntriesInnerAccessEnum.edit: 'edit',
  SetBotAccessRequestEntriesInnerAccessEnum.admin: 'admin',
};
