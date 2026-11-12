// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_history_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerHistoryEntryCWProxy {
  ComputerHistoryEntry id(String id);

  ComputerHistoryEntry action(String action);

  ComputerHistoryEntry actorType(ComputerHistoryEntryActorTypeEnum actorType);

  ComputerHistoryEntry actorId(String? actorId);

  ComputerHistoryEntry actorName(String? actorName);

  ComputerHistoryEntry metadata(Map<String, Object?> metadata);

  ComputerHistoryEntry createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerHistoryEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerHistoryEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerHistoryEntry call({
    String id,
    String action,
    ComputerHistoryEntryActorTypeEnum actorType,
    String? actorId,
    String? actorName,
    Map<String, Object?> metadata,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerHistoryEntry.copyWith(...)` or call `instanceOfComputerHistoryEntry.copyWith.fieldName(value)` for a single field.
class _$ComputerHistoryEntryCWProxyImpl
    implements _$ComputerHistoryEntryCWProxy {
  const _$ComputerHistoryEntryCWProxyImpl(this._value);

  final ComputerHistoryEntry _value;

  @override
  ComputerHistoryEntry id(String id) => call(id: id);

  @override
  ComputerHistoryEntry action(String action) => call(action: action);

  @override
  ComputerHistoryEntry actorType(ComputerHistoryEntryActorTypeEnum actorType) =>
      call(actorType: actorType);

  @override
  ComputerHistoryEntry actorId(String? actorId) => call(actorId: actorId);

  @override
  ComputerHistoryEntry actorName(String? actorName) =>
      call(actorName: actorName);

  @override
  ComputerHistoryEntry metadata(Map<String, Object?> metadata) =>
      call(metadata: metadata);

  @override
  ComputerHistoryEntry createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerHistoryEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerHistoryEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerHistoryEntry call({
    Object? id = const $CopyWithPlaceholder(),
    Object? action = const $CopyWithPlaceholder(),
    Object? actorType = const $CopyWithPlaceholder(),
    Object? actorId = const $CopyWithPlaceholder(),
    Object? actorName = const $CopyWithPlaceholder(),
    Object? metadata = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ComputerHistoryEntry(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      action: action == const $CopyWithPlaceholder() || action == null
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as String,
      actorType: actorType == const $CopyWithPlaceholder() || actorType == null
          ? _value.actorType
          // ignore: cast_nullable_to_non_nullable
          : actorType as ComputerHistoryEntryActorTypeEnum,
      actorId: actorId == const $CopyWithPlaceholder()
          ? _value.actorId
          // ignore: cast_nullable_to_non_nullable
          : actorId as String?,
      actorName: actorName == const $CopyWithPlaceholder()
          ? _value.actorName
          // ignore: cast_nullable_to_non_nullable
          : actorName as String?,
      metadata: metadata == const $CopyWithPlaceholder() || metadata == null
          ? _value.metadata
          // ignore: cast_nullable_to_non_nullable
          : metadata as Map<String, Object?>,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ComputerHistoryEntryCopyWith on ComputerHistoryEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerHistoryEntry.copyWith(...)` or `instanceOfComputerHistoryEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerHistoryEntryCWProxy get copyWith =>
      _$ComputerHistoryEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerHistoryEntry _$ComputerHistoryEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ComputerHistoryEntry',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'action',
        'actor_type',
        'actor_id',
        'actor_name',
        'metadata',
        'created_at',
      ],
    );
    final val = ComputerHistoryEntry(
      id: $checkedConvert('id', (v) => v as String),
      action: $checkedConvert('action', (v) => v as String),
      actorType: $checkedConvert(
        'actor_type',
        (v) => $enumDecode(_$ComputerHistoryEntryActorTypeEnumEnumMap, v),
      ),
      actorId: $checkedConvert('actor_id', (v) => v as String?),
      actorName: $checkedConvert('actor_name', (v) => v as String?),
      metadata: $checkedConvert('metadata', (v) => v as Map<String, dynamic>),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'actorType': 'actor_type',
    'actorId': 'actor_id',
    'actorName': 'actor_name',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ComputerHistoryEntryToJson(
  ComputerHistoryEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'action': instance.action,
  'actor_type': _$ComputerHistoryEntryActorTypeEnumEnumMap[instance.actorType]!,
  'actor_id': instance.actorId,
  'actor_name': instance.actorName,
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$ComputerHistoryEntryActorTypeEnumEnumMap = {
  ComputerHistoryEntryActorTypeEnum.user: 'user',
  ComputerHistoryEntryActorTypeEnum.bot: 'bot',
  ComputerHistoryEntryActorTypeEnum.system: 'system',
};
