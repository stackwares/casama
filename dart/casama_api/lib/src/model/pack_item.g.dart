// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackItemCWProxy {
  PackItem kind(PackItemKind kind);

  PackItem id(String id);

  PackItem name(String name);

  PackItem targetId(String? targetId);

  PackItem botId(String? botId);

  PackItem edited(bool edited);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackItem(...).copyWith(id: 12, name: "My name")
  /// ```
  PackItem call({
    PackItemKind kind,
    String id,
    String name,
    String? targetId,
    String? botId,
    bool edited,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackItem.copyWith(...)` or call `instanceOfPackItem.copyWith.fieldName(value)` for a single field.
class _$PackItemCWProxyImpl implements _$PackItemCWProxy {
  const _$PackItemCWProxyImpl(this._value);

  final PackItem _value;

  @override
  PackItem kind(PackItemKind kind) => call(kind: kind);

  @override
  PackItem id(String id) => call(id: id);

  @override
  PackItem name(String name) => call(name: name);

  @override
  PackItem targetId(String? targetId) => call(targetId: targetId);

  @override
  PackItem botId(String? botId) => call(botId: botId);

  @override
  PackItem edited(bool edited) => call(edited: edited);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackItem call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? targetId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? edited = const $CopyWithPlaceholder(),
  }) {
    return PackItem(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PackItemKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      targetId: targetId == const $CopyWithPlaceholder()
          ? _value.targetId
          // ignore: cast_nullable_to_non_nullable
          : targetId as String?,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      edited: edited == const $CopyWithPlaceholder() || edited == null
          ? _value.edited
          // ignore: cast_nullable_to_non_nullable
          : edited as bool,
    );
  }
}

extension $PackItemCopyWith on PackItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackItem.copyWith(...)` or `instanceOfPackItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackItemCWProxy get copyWith => _$PackItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackItem _$PackItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackItem', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['kind', 'id', 'name', 'target_id', 'bot_id', 'edited'],
  );
  final val = PackItem(
    kind: $checkedConvert('kind', (v) => $enumDecode(_$PackItemKindEnumMap, v)),
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    targetId: $checkedConvert('target_id', (v) => v as String?),
    botId: $checkedConvert('bot_id', (v) => v as String?),
    edited: $checkedConvert('edited', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'targetId': 'target_id', 'botId': 'bot_id'});

Map<String, dynamic> _$PackItemToJson(PackItem instance) => <String, dynamic>{
  'kind': _$PackItemKindEnumMap[instance.kind]!,
  'id': instance.id,
  'name': instance.name,
  'target_id': instance.targetId,
  'bot_id': instance.botId,
  'edited': instance.edited,
};

const _$PackItemKindEnumMap = {
  PackItemKind.bot: 'bot',
  PackItemKind.skill: 'skill',
  PackItemKind.routine: 'routine',
  PackItemKind.app: 'app',
  PackItemKind.look: 'look',
  PackItemKind.tools: 'tools',
  PackItemKind.include: 'include',
};
