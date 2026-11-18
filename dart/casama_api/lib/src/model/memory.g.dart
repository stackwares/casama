// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryCWProxy {
  Memory id(String id);

  Memory kind(MemoryKindEnum kind);

  Memory content(String content);

  Memory importance(num importance);

  Memory pinned(bool pinned);

  Memory createdAt(DateTime createdAt);

  Memory updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Memory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Memory(...).copyWith(id: 12, name: "My name")
  /// ```
  Memory call({
    String id,
    MemoryKindEnum kind,
    String content,
    num importance,
    bool pinned,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemory.copyWith(...)` or call `instanceOfMemory.copyWith.fieldName(value)` for a single field.
class _$MemoryCWProxyImpl implements _$MemoryCWProxy {
  const _$MemoryCWProxyImpl(this._value);

  final Memory _value;

  @override
  Memory id(String id) => call(id: id);

  @override
  Memory kind(MemoryKindEnum kind) => call(kind: kind);

  @override
  Memory content(String content) => call(content: content);

  @override
  Memory importance(num importance) => call(importance: importance);

  @override
  Memory pinned(bool pinned) => call(pinned: pinned);

  @override
  Memory createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Memory updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Memory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Memory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Memory call({
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
    Object? importance = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Memory(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as MemoryKindEnum,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
      importance:
          importance == const $CopyWithPlaceholder() || importance == null
          ? _value.importance
          // ignore: cast_nullable_to_non_nullable
          : importance as num,
      pinned: pinned == const $CopyWithPlaceholder() || pinned == null
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $MemoryCopyWith on Memory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemory.copyWith(...)` or `instanceOfMemory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemoryCWProxy get copyWith => _$MemoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Memory _$MemoryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Memory',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'kind',
        'content',
        'importance',
        'pinned',
        'created_at',
        'updated_at',
      ],
    );
    final val = Memory(
      id: $checkedConvert('id', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$MemoryKindEnumEnumMap, v),
      ),
      content: $checkedConvert('content', (v) => v as String),
      importance: $checkedConvert('importance', (v) => v as num),
      pinned: $checkedConvert('pinned', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'createdAt': 'created_at', 'updatedAt': 'updated_at'},
);

Map<String, dynamic> _$MemoryToJson(Memory instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$MemoryKindEnumEnumMap[instance.kind]!,
  'content': instance.content,
  'importance': instance.importance,
  'pinned': instance.pinned,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$MemoryKindEnumEnumMap = {
  MemoryKindEnum.fact: 'fact',
  MemoryKindEnum.episode: 'episode',
  MemoryKindEnum.summary: 'summary',
  MemoryKindEnum.preference: 'preference',
};
