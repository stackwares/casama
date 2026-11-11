// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$KnowledgeSourceCWProxy {
  KnowledgeSource id(String id);

  KnowledgeSource botId(String? botId);

  KnowledgeSource kind(KnowledgeSourceKindEnum kind);

  KnowledgeSource name(String name);

  KnowledgeSource config(Map<String, Object?> config);

  KnowledgeSource status(KnowledgeSourceStatusEnum status);

  KnowledgeSource error(String? error);

  KnowledgeSource documents(int documents);

  KnowledgeSource chunks(int chunks);

  KnowledgeSource lastSyncedAt(DateTime? lastSyncedAt);

  KnowledgeSource createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `KnowledgeSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// KnowledgeSource(...).copyWith(id: 12, name: "My name")
  /// ```
  KnowledgeSource call({
    String id,
    String? botId,
    KnowledgeSourceKindEnum kind,
    String name,
    Map<String, Object?> config,
    KnowledgeSourceStatusEnum status,
    String? error,
    int documents,
    int chunks,
    DateTime? lastSyncedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfKnowledgeSource.copyWith(...)` or call `instanceOfKnowledgeSource.copyWith.fieldName(value)` for a single field.
class _$KnowledgeSourceCWProxyImpl implements _$KnowledgeSourceCWProxy {
  const _$KnowledgeSourceCWProxyImpl(this._value);

  final KnowledgeSource _value;

  @override
  KnowledgeSource id(String id) => call(id: id);

  @override
  KnowledgeSource botId(String? botId) => call(botId: botId);

  @override
  KnowledgeSource kind(KnowledgeSourceKindEnum kind) => call(kind: kind);

  @override
  KnowledgeSource name(String name) => call(name: name);

  @override
  KnowledgeSource config(Map<String, Object?> config) => call(config: config);

  @override
  KnowledgeSource status(KnowledgeSourceStatusEnum status) =>
      call(status: status);

  @override
  KnowledgeSource error(String? error) => call(error: error);

  @override
  KnowledgeSource documents(int documents) => call(documents: documents);

  @override
  KnowledgeSource chunks(int chunks) => call(chunks: chunks);

  @override
  KnowledgeSource lastSyncedAt(DateTime? lastSyncedAt) =>
      call(lastSyncedAt: lastSyncedAt);

  @override
  KnowledgeSource createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `KnowledgeSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// KnowledgeSource(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  KnowledgeSource call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? config = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? documents = const $CopyWithPlaceholder(),
    Object? chunks = const $CopyWithPlaceholder(),
    Object? lastSyncedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return KnowledgeSource(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as KnowledgeSourceKindEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      config: config == const $CopyWithPlaceholder() || config == null
          ? _value.config
          // ignore: cast_nullable_to_non_nullable
          : config as Map<String, Object?>,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as KnowledgeSourceStatusEnum,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      documents: documents == const $CopyWithPlaceholder() || documents == null
          ? _value.documents
          // ignore: cast_nullable_to_non_nullable
          : documents as int,
      chunks: chunks == const $CopyWithPlaceholder() || chunks == null
          ? _value.chunks
          // ignore: cast_nullable_to_non_nullable
          : chunks as int,
      lastSyncedAt: lastSyncedAt == const $CopyWithPlaceholder()
          ? _value.lastSyncedAt
          // ignore: cast_nullable_to_non_nullable
          : lastSyncedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $KnowledgeSourceCopyWith on KnowledgeSource {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfKnowledgeSource.copyWith(...)` or `instanceOfKnowledgeSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$KnowledgeSourceCWProxy get copyWith => _$KnowledgeSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KnowledgeSource _$KnowledgeSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'KnowledgeSource',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'bot_id',
            'kind',
            'name',
            'config',
            'status',
            'error',
            'documents',
            'chunks',
            'last_synced_at',
            'created_at',
          ],
        );
        final val = KnowledgeSource(
          id: $checkedConvert('id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String?),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$KnowledgeSourceKindEnumEnumMap, v),
          ),
          name: $checkedConvert('name', (v) => v as String),
          config: $checkedConvert('config', (v) => v as Map<String, dynamic>),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$KnowledgeSourceStatusEnumEnumMap, v),
          ),
          error: $checkedConvert('error', (v) => v as String?),
          documents: $checkedConvert('documents', (v) => (v as num).toInt()),
          chunks: $checkedConvert('chunks', (v) => (v as num).toInt()),
          lastSyncedAt: $checkedConvert(
            'last_synced_at',
            (v) => v == null ? null : DateTime.parse(v as String),
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
        'lastSyncedAt': 'last_synced_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$KnowledgeSourceToJson(KnowledgeSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'kind': _$KnowledgeSourceKindEnumEnumMap[instance.kind]!,
      'name': instance.name,
      'config': instance.config,
      'status': _$KnowledgeSourceStatusEnumEnumMap[instance.status]!,
      'error': instance.error,
      'documents': instance.documents,
      'chunks': instance.chunks,
      'last_synced_at': instance.lastSyncedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$KnowledgeSourceKindEnumEnumMap = {
  KnowledgeSourceKindEnum.upload: 'upload',
  KnowledgeSourceKindEnum.website: 'website',
  KnowledgeSourceKindEnum.github: 'github',
  KnowledgeSourceKindEnum.connection: 'connection',
};

const _$KnowledgeSourceStatusEnumEnumMap = {
  KnowledgeSourceStatusEnum.pending: 'pending',
  KnowledgeSourceStatusEnum.syncing: 'syncing',
  KnowledgeSourceStatusEnum.ready: 'ready',
  KnowledgeSourceStatusEnum.error: 'error',
};
