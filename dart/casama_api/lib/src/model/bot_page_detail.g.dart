// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_page_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotPageDetailCWProxy {
  BotPageDetail id(String id);

  BotPageDetail botId(String botId);

  BotPageDetail title(String title);

  BotPageDetail visibility(BotPageDetailVisibilityEnum visibility);

  BotPageDetail version(int version);

  BotPageDetail expiresAt(DateTime? expiresAt);

  BotPageDetail refreshRoutineId(String? refreshRoutineId);

  BotPageDetail conversationId(String? conversationId);

  BotPageDetail canManage(bool canManage);

  BotPageDetail updatedAt(DateTime updatedAt);

  BotPageDetail createdAt(DateTime createdAt);

  BotPageDetail versions(List<PageVersion> versions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPageDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPageDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  BotPageDetail call({
    String id,
    String botId,
    String title,
    BotPageDetailVisibilityEnum visibility,
    int version,
    DateTime? expiresAt,
    String? refreshRoutineId,
    String? conversationId,
    bool canManage,
    DateTime updatedAt,
    DateTime createdAt,
    List<PageVersion> versions,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotPageDetail.copyWith(...)` or call `instanceOfBotPageDetail.copyWith.fieldName(value)` for a single field.
class _$BotPageDetailCWProxyImpl implements _$BotPageDetailCWProxy {
  const _$BotPageDetailCWProxyImpl(this._value);

  final BotPageDetail _value;

  @override
  BotPageDetail id(String id) => call(id: id);

  @override
  BotPageDetail botId(String botId) => call(botId: botId);

  @override
  BotPageDetail title(String title) => call(title: title);

  @override
  BotPageDetail visibility(BotPageDetailVisibilityEnum visibility) =>
      call(visibility: visibility);

  @override
  BotPageDetail version(int version) => call(version: version);

  @override
  BotPageDetail expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  BotPageDetail refreshRoutineId(String? refreshRoutineId) =>
      call(refreshRoutineId: refreshRoutineId);

  @override
  BotPageDetail conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  BotPageDetail canManage(bool canManage) => call(canManage: canManage);

  @override
  BotPageDetail updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  BotPageDetail createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  BotPageDetail versions(List<PageVersion> versions) =>
      call(versions: versions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPageDetail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPageDetail(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotPageDetail call({
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
    Object? versions = const $CopyWithPlaceholder(),
  }) {
    return BotPageDetail(
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
          : visibility as BotPageDetailVisibilityEnum,
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
      versions: versions == const $CopyWithPlaceholder() || versions == null
          ? _value.versions
          // ignore: cast_nullable_to_non_nullable
          : versions as List<PageVersion>,
    );
  }
}

extension $BotPageDetailCopyWith on BotPageDetail {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotPageDetail.copyWith(...)` or `instanceOfBotPageDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotPageDetailCWProxy get copyWith => _$BotPageDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotPageDetail _$BotPageDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BotPageDetail',
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
            'versions',
          ],
        );
        final val = BotPageDetail(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          visibility: $checkedConvert(
            'visibility',
            (v) => $enumDecode(_$BotPageDetailVisibilityEnumEnumMap, v),
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
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String?,
          ),
          canManage: $checkedConvert('can_manage', (v) => v as bool),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          versions: $checkedConvert(
            'versions',
            (v) => (v as List<dynamic>)
                .map((e) => PageVersion.fromJson(e as Map<String, dynamic>))
                .toList(),
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

Map<String, dynamic> _$BotPageDetailToJson(BotPageDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'title': instance.title,
      'visibility': _$BotPageDetailVisibilityEnumEnumMap[instance.visibility]!,
      'version': instance.version,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'refresh_routine_id': instance.refreshRoutineId,
      'conversation_id': instance.conversationId,
      'can_manage': instance.canManage,
      'updated_at': instance.updatedAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'versions': instance.versions.map((e) => e.toJson()).toList(),
    };

const _$BotPageDetailVisibilityEnumEnumMap = {
  BotPageDetailVisibilityEnum.private: 'private',
  BotPageDetailVisibilityEnum.workspace: 'workspace',
  BotPageDetailVisibilityEnum.public: 'public',
};
