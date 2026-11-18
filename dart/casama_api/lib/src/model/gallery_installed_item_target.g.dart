// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_installed_item_target.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInstalledItemTargetCWProxy {
  GalleryInstalledItemTarget kind(GalleryWorkspaceKind kind);

  GalleryInstalledItemTarget id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstalledItemTarget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstalledItemTarget(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInstalledItemTarget call({GalleryWorkspaceKind kind, String id});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInstalledItemTarget.copyWith(...)` or call `instanceOfGalleryInstalledItemTarget.copyWith.fieldName(value)` for a single field.
class _$GalleryInstalledItemTargetCWProxyImpl
    implements _$GalleryInstalledItemTargetCWProxy {
  const _$GalleryInstalledItemTargetCWProxyImpl(this._value);

  final GalleryInstalledItemTarget _value;

  @override
  GalleryInstalledItemTarget kind(GalleryWorkspaceKind kind) =>
      call(kind: kind);

  @override
  GalleryInstalledItemTarget id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstalledItemTarget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstalledItemTarget(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInstalledItemTarget call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return GalleryInstalledItemTarget(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GalleryWorkspaceKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $GalleryInstalledItemTargetCopyWith on GalleryInstalledItemTarget {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInstalledItemTarget.copyWith(...)` or `instanceOfGalleryInstalledItemTarget.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInstalledItemTargetCWProxy get copyWith =>
      _$GalleryInstalledItemTargetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInstalledItemTarget _$GalleryInstalledItemTargetFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryInstalledItemTarget', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'id']);
  final val = GalleryInstalledItemTarget(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$GalleryWorkspaceKindEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$GalleryInstalledItemTargetToJson(
  GalleryInstalledItemTarget instance,
) => <String, dynamic>{
  'kind': _$GalleryWorkspaceKindEnumMap[instance.kind]!,
  'id': instance.id,
};

const _$GalleryWorkspaceKindEnumMap = {
  GalleryWorkspaceKind.skill: 'skill',
  GalleryWorkspaceKind.app: 'app',
  GalleryWorkspaceKind.bot: 'bot',
  GalleryWorkspaceKind.routine: 'routine',
  GalleryWorkspaceKind.plugin: 'plugin',
};
