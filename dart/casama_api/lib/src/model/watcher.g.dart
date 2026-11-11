// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watcher.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatcherCWProxy {
  Watcher id(String id);

  Watcher botId(String botId);

  Watcher name(String name);

  Watcher kind(WatcherKindEnum kind);

  Watcher target(Map<String, Object?> target);

  Watcher conditionMd(String conditionMd);

  Watcher status(WatcherStatusEnum status);

  Watcher checkEverySeconds(int checkEverySeconds);

  Watcher firedCount(int firedCount);

  Watcher lastCheckedAt(DateTime? lastCheckedAt);

  Watcher lastError(String? lastError);

  Watcher expiresAt(DateTime? expiresAt);

  Watcher conversationId(String? conversationId);

  Watcher createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Watcher(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Watcher(...).copyWith(id: 12, name: "My name")
  /// ```
  Watcher call({
    String id,
    String botId,
    String name,
    WatcherKindEnum kind,
    Map<String, Object?> target,
    String conditionMd,
    WatcherStatusEnum status,
    int checkEverySeconds,
    int firedCount,
    DateTime? lastCheckedAt,
    String? lastError,
    DateTime? expiresAt,
    String? conversationId,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatcher.copyWith(...)` or call `instanceOfWatcher.copyWith.fieldName(value)` for a single field.
class _$WatcherCWProxyImpl implements _$WatcherCWProxy {
  const _$WatcherCWProxyImpl(this._value);

  final Watcher _value;

  @override
  Watcher id(String id) => call(id: id);

  @override
  Watcher botId(String botId) => call(botId: botId);

  @override
  Watcher name(String name) => call(name: name);

  @override
  Watcher kind(WatcherKindEnum kind) => call(kind: kind);

  @override
  Watcher target(Map<String, Object?> target) => call(target: target);

  @override
  Watcher conditionMd(String conditionMd) => call(conditionMd: conditionMd);

  @override
  Watcher status(WatcherStatusEnum status) => call(status: status);

  @override
  Watcher checkEverySeconds(int checkEverySeconds) =>
      call(checkEverySeconds: checkEverySeconds);

  @override
  Watcher firedCount(int firedCount) => call(firedCount: firedCount);

  @override
  Watcher lastCheckedAt(DateTime? lastCheckedAt) =>
      call(lastCheckedAt: lastCheckedAt);

  @override
  Watcher lastError(String? lastError) => call(lastError: lastError);

  @override
  Watcher expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  Watcher conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  Watcher createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Watcher(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Watcher(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Watcher call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
    Object? conditionMd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? checkEverySeconds = const $CopyWithPlaceholder(),
    Object? firedCount = const $CopyWithPlaceholder(),
    Object? lastCheckedAt = const $CopyWithPlaceholder(),
    Object? lastError = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Watcher(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as WatcherKindEnum,
      target: target == const $CopyWithPlaceholder() || target == null
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as Map<String, Object?>,
      conditionMd:
          conditionMd == const $CopyWithPlaceholder() || conditionMd == null
          ? _value.conditionMd
          // ignore: cast_nullable_to_non_nullable
          : conditionMd as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as WatcherStatusEnum,
      checkEverySeconds:
          checkEverySeconds == const $CopyWithPlaceholder() ||
              checkEverySeconds == null
          ? _value.checkEverySeconds
          // ignore: cast_nullable_to_non_nullable
          : checkEverySeconds as int,
      firedCount:
          firedCount == const $CopyWithPlaceholder() || firedCount == null
          ? _value.firedCount
          // ignore: cast_nullable_to_non_nullable
          : firedCount as int,
      lastCheckedAt: lastCheckedAt == const $CopyWithPlaceholder()
          ? _value.lastCheckedAt
          // ignore: cast_nullable_to_non_nullable
          : lastCheckedAt as DateTime?,
      lastError: lastError == const $CopyWithPlaceholder()
          ? _value.lastError
          // ignore: cast_nullable_to_non_nullable
          : lastError as String?,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $WatcherCopyWith on Watcher {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatcher.copyWith(...)` or `instanceOfWatcher.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatcherCWProxy get copyWith => _$WatcherCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Watcher _$WatcherFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Watcher',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'name',
        'kind',
        'target',
        'condition_md',
        'status',
        'check_every_seconds',
        'fired_count',
        'last_checked_at',
        'last_error',
        'expires_at',
        'conversation_id',
        'created_at',
      ],
    );
    final val = Watcher(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$WatcherKindEnumEnumMap, v),
      ),
      target: $checkedConvert('target', (v) => v as Map<String, dynamic>),
      conditionMd: $checkedConvert('condition_md', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$WatcherStatusEnumEnumMap, v),
      ),
      checkEverySeconds: $checkedConvert(
        'check_every_seconds',
        (v) => (v as num).toInt(),
      ),
      firedCount: $checkedConvert('fired_count', (v) => (v as num).toInt()),
      lastCheckedAt: $checkedConvert(
        'last_checked_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastError: $checkedConvert('last_error', (v) => v as String?),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'conditionMd': 'condition_md',
    'checkEverySeconds': 'check_every_seconds',
    'firedCount': 'fired_count',
    'lastCheckedAt': 'last_checked_at',
    'lastError': 'last_error',
    'expiresAt': 'expires_at',
    'conversationId': 'conversation_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$WatcherToJson(Watcher instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'name': instance.name,
  'kind': _$WatcherKindEnumEnumMap[instance.kind]!,
  'target': instance.target,
  'condition_md': instance.conditionMd,
  'status': _$WatcherStatusEnumEnumMap[instance.status]!,
  'check_every_seconds': instance.checkEverySeconds,
  'fired_count': instance.firedCount,
  'last_checked_at': instance.lastCheckedAt?.toIso8601String(),
  'last_error': instance.lastError,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'conversation_id': instance.conversationId,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$WatcherKindEnumEnumMap = {
  WatcherKindEnum.pageChange: 'page_change',
  WatcherKindEnum.reply: 'reply',
  WatcherKindEnum.query: 'query',
  WatcherKindEnum.time: 'time',
};

const _$WatcherStatusEnumEnumMap = {
  WatcherStatusEnum.active: 'active',
  WatcherStatusEnum.paused: 'paused',
  WatcherStatusEnum.done: 'done',
  WatcherStatusEnum.expired: 'expired',
};
