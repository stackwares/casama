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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Memory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Memory(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMemory.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMemory.copyWith.fieldName(...)`
class _$MemoryCWProxyImpl implements _$MemoryCWProxy {
  const _$MemoryCWProxyImpl(this._value);

  final Memory _value;

  @override
  Memory id(String id) => this(id: id);

  @override
  Memory kind(MemoryKindEnum kind) => this(kind: kind);

  @override
  Memory content(String content) => this(content: content);

  @override
  Memory importance(num importance) => this(importance: importance);

  @override
  Memory pinned(bool pinned) => this(pinned: pinned);

  @override
  Memory createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  Memory updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Memory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Memory(...).copyWith(id: 12, name: "My name")
  /// ````
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
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as MemoryKindEnum,
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as String,
      importance: importance == const $CopyWithPlaceholder()
          ? _value.importance
          // ignore: cast_nullable_to_non_nullable
          : importance as num,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $MemoryCopyWith on Memory {
  /// Returns a callable class that can be used as follows: `instanceOfMemory.copyWith(...)` or like so:`instanceOfMemory.copyWith.fieldName(...)`.
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
