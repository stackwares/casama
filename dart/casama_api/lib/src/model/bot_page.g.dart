// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotPageCWProxy {
  BotPage id(String id);

  BotPage botId(String botId);

  BotPage title(String title);

  BotPage visibility(BotPageVisibilityEnum visibility);

  BotPage version(int version);

  BotPage expiresAt(DateTime? expiresAt);

  BotPage refreshRoutineId(String? refreshRoutineId);

  BotPage conversationId(String? conversationId);

  BotPage canManage(bool canManage);

  BotPage updatedAt(DateTime updatedAt);

  BotPage createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPage(...).copyWith(id: 12, name: "My name")
  /// ```
  BotPage call({
    String id,
    String botId,
    String title,
    BotPageVisibilityEnum visibility,
    int version,
    DateTime? expiresAt,
    String? refreshRoutineId,
    String? conversationId,
    bool canManage,
    DateTime updatedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotPage.copyWith(...)` or call `instanceOfBotPage.copyWith.fieldName(value)` for a single field.
class _$BotPageCWProxyImpl implements _$BotPageCWProxy {
  const _$BotPageCWProxyImpl(this._value);

  final BotPage _value;

  @override
  BotPage id(String id) => call(id: id);

  @override
  BotPage botId(String botId) => call(botId: botId);

  @override
  BotPage title(String title) => call(title: title);

  @override
  BotPage visibility(BotPageVisibilityEnum visibility) =>
      call(visibility: visibility);

  @override
  BotPage version(int version) => call(version: version);

  @override
  BotPage expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  BotPage refreshRoutineId(String? refreshRoutineId) =>
      call(refreshRoutineId: refreshRoutineId);

  @override
  BotPage conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  BotPage canManage(bool canManage) => call(canManage: canManage);

  @override
  BotPage updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  BotPage createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotPage call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? visibility = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? refreshRoutineId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? canManage = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return BotPage(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      visibility:
          visibility == const $CopyWithPlaceholder() || visibility == null
          ? _value.visibility
          // ignore: cast_nullable_to_non_nullable
          : visibility as BotPageVisibilityEnum,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      refreshRoutineId: refreshRoutineId == const $CopyWithPlaceholder()
          ? _value.refreshRoutineId
          // ignore: cast_nullable_to_non_nullable
          : refreshRoutineId as String?,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      canManage: canManage == const $CopyWithPlaceholder() || canManage == null
          ? _value.canManage
          // ignore: cast_nullable_to_non_nullable
          : canManage as bool,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $BotPageCopyWith on BotPage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotPage.copyWith(...)` or `instanceOfBotPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotPageCWProxy get copyWith => _$BotPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotPage _$BotPageFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotPage',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'title',
        'visibility',
        'version',
        'expires_at',
        'refresh_routine_id',
        'conversation_id',
        'can_manage',
        'updated_at',
        'created_at',
      ],
    );
    final val = BotPage(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      visibility: $checkedConvert(
        'visibility',
        (v) => $enumDecode(_$BotPageVisibilityEnumEnumMap, v),
      ),
      version: $checkedConvert('version', (v) => (v as num).toInt()),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      refreshRoutineId: $checkedConvert(
        'refresh_routine_id',
        (v) => v as String?,
      ),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      canManage: $checkedConvert('can_manage', (v) => v as bool),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'expiresAt': 'expires_at',
    'refreshRoutineId': 'refresh_routine_id',
    'conversationId': 'conversation_id',
    'canManage': 'can_manage',
    'updatedAt': 'updated_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$BotPageToJson(BotPage instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'title': instance.title,
  'visibility': _$BotPageVisibilityEnumEnumMap[instance.visibility]!,
  'version': instance.version,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'refresh_routine_id': instance.refreshRoutineId,
  'conversation_id': instance.conversationId,
  'can_manage': instance.canManage,
  'updated_at': instance.updatedAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$BotPageVisibilityEnumEnumMap = {
  BotPageVisibilityEnum.private: 'private',
  BotPageVisibilityEnum.workspace: 'workspace',
  BotPageVisibilityEnum.public: 'public',
};
