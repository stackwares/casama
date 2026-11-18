// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_install_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackInstallItemCWProxy {
  PackInstallItem kind(PackItemKind kind);

  PackInstallItem id(String id);

  PackInstallItem name(String name);

  PackInstallItem status(PackInstallItemStatusEnum status);

  PackInstallItem targetId(String? targetId);

  PackInstallItem error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackInstallItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackInstallItem(...).copyWith(id: 12, name: "My name")
  /// ```
  PackInstallItem call({
    PackItemKind kind,
    String id,
    String name,
    PackInstallItemStatusEnum status,
    String? targetId,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackInstallItem.copyWith(...)` or call `instanceOfPackInstallItem.copyWith.fieldName(value)` for a single field.
class _$PackInstallItemCWProxyImpl implements _$PackInstallItemCWProxy {
  const _$PackInstallItemCWProxyImpl(this._value);

  final PackInstallItem _value;

  @override
  PackInstallItem kind(PackItemKind kind) => call(kind: kind);

  @override
  PackInstallItem id(String id) => call(id: id);

  @override
  PackInstallItem name(String name) => call(name: name);

  @override
  PackInstallItem status(PackInstallItemStatusEnum status) =>
      call(status: status);

  @override
  PackInstallItem targetId(String? targetId) => call(targetId: targetId);

  @override
  PackInstallItem error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackInstallItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackInstallItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackInstallItem call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? targetId = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return PackInstallItem(
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
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PackInstallItemStatusEnum,
      targetId: targetId == const $CopyWithPlaceholder()
          ? _value.targetId
          // ignore: cast_nullable_to_non_nullable
          : targetId as String?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $PackInstallItemCopyWith on PackInstallItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackInstallItem.copyWith(...)` or `instanceOfPackInstallItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackInstallItemCWProxy get copyWith => _$PackInstallItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackInstallItem _$PackInstallItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackInstallItem', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['kind', 'id', 'name', 'status', 'target_id', 'error'],
  );
  final val = PackInstallItem(
    kind: $checkedConvert('kind', (v) => $enumDecode(_$PackItemKindEnumMap, v)),
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$PackInstallItemStatusEnumEnumMap, v),
    ),
    targetId: $checkedConvert('target_id', (v) => v as String?),
    error: $checkedConvert('error', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'targetId': 'target_id'});

Map<String, dynamic> _$PackInstallItemToJson(PackInstallItem instance) =>
    <String, dynamic>{
      'kind': _$PackItemKindEnumMap[instance.kind]!,
      'id': instance.id,
      'name': instance.name,
      'status': _$PackInstallItemStatusEnumEnumMap[instance.status]!,
      'target_id': instance.targetId,
      'error': instance.error,
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

const _$PackInstallItemStatusEnumEnumMap = {
  PackInstallItemStatusEnum.installed: 'installed',
  PackInstallItemStatusEnum.approvalPending: 'approval_pending',
  PackInstallItemStatusEnum.skipped: 'skipped',
  PackInstallItemStatusEnum.failed: 'failed',
  PackInstallItemStatusEnum.device: 'device',
};
