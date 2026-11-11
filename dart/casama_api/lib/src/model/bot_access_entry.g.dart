// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_access_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotAccessEntryCWProxy {
  BotAccessEntry userId(String? userId);

  BotAccessEntry email(String? email);

  BotAccessEntry role(BotAccessEntryRoleEnum? role);

  BotAccessEntry access(BotAccessEntryAccessEnum access);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotAccessEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotAccessEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  BotAccessEntry call({
    String? userId,
    String? email,
    BotAccessEntryRoleEnum? role,
    BotAccessEntryAccessEnum access,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotAccessEntry.copyWith(...)` or call `instanceOfBotAccessEntry.copyWith.fieldName(value)` for a single field.
class _$BotAccessEntryCWProxyImpl implements _$BotAccessEntryCWProxy {
  const _$BotAccessEntryCWProxyImpl(this._value);

  final BotAccessEntry _value;

  @override
  BotAccessEntry userId(String? userId) => call(userId: userId);

  @override
  BotAccessEntry email(String? email) => call(email: email);

  @override
  BotAccessEntry role(BotAccessEntryRoleEnum? role) => call(role: role);

  @override
  BotAccessEntry access(BotAccessEntryAccessEnum access) =>
      call(access: access);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotAccessEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotAccessEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotAccessEntry call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? role = const $CopyWithPlaceholder(),
    Object? access = const $CopyWithPlaceholder(),
  }) {
    return BotAccessEntry(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String?,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as BotAccessEntryRoleEnum?,
      access: access == const $CopyWithPlaceholder() || access == null
          ? _value.access
          // ignore: cast_nullable_to_non_nullable
          : access as BotAccessEntryAccessEnum,
    );
  }
}

extension $BotAccessEntryCopyWith on BotAccessEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotAccessEntry.copyWith(...)` or `instanceOfBotAccessEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotAccessEntryCWProxy get copyWith => _$BotAccessEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotAccessEntry _$BotAccessEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotAccessEntry', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['user_id', 'email', 'role', 'access'],
      );
      final val = BotAccessEntry(
        userId: $checkedConvert('user_id', (v) => v as String?),
        email: $checkedConvert('email', (v) => v as String?),
        role: $checkedConvert(
          'role',
          (v) => $enumDecodeNullable(_$BotAccessEntryRoleEnumEnumMap, v),
        ),
        access: $checkedConvert(
          'access',
          (v) => $enumDecode(_$BotAccessEntryAccessEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id'});

Map<String, dynamic> _$BotAccessEntryToJson(BotAccessEntry instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'role': _$BotAccessEntryRoleEnumEnumMap[instance.role],
      'access': _$BotAccessEntryAccessEnumEnumMap[instance.access]!,
    };

const _$BotAccessEntryRoleEnumEnumMap = {
  BotAccessEntryRoleEnum.owner: 'owner',
  BotAccessEntryRoleEnum.admin: 'admin',
  BotAccessEntryRoleEnum.member: 'member',
};

const _$BotAccessEntryAccessEnumEnumMap = {
  BotAccessEntryAccessEnum.chat: 'chat',
  BotAccessEntryAccessEnum.edit: 'edit',
  BotAccessEntryAccessEnum.admin: 'admin',
};
