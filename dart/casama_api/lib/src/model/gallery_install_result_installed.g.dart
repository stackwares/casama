// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_install_result_installed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryInstallResultInstalledCWProxy {
  GalleryInstallResultInstalled kind(GalleryWorkspaceKind kind);

  GalleryInstallResultInstalled id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstallResultInstalled(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstallResultInstalled(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryInstallResultInstalled call({GalleryWorkspaceKind kind, String id});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryInstallResultInstalled.copyWith(...)` or call `instanceOfGalleryInstallResultInstalled.copyWith.fieldName(value)` for a single field.
class _$GalleryInstallResultInstalledCWProxyImpl
    implements _$GalleryInstallResultInstalledCWProxy {
  const _$GalleryInstallResultInstalledCWProxyImpl(this._value);

  final GalleryInstallResultInstalled _value;

  @override
  GalleryInstallResultInstalled kind(GalleryWorkspaceKind kind) =>
      call(kind: kind);

  @override
  GalleryInstallResultInstalled id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryInstallResultInstalled(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryInstallResultInstalled(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryInstallResultInstalled call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return GalleryInstallResultInstalled(
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

extension $GalleryInstallResultInstalledCopyWith
    on GalleryInstallResultInstalled {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryInstallResultInstalled.copyWith(...)` or `instanceOfGalleryInstallResultInstalled.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryInstallResultInstalledCWProxy get copyWith =>
      _$GalleryInstallResultInstalledCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInstallResultInstalled _$GalleryInstallResultInstalledFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryInstallResultInstalled', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'id']);
  final val = GalleryInstallResultInstalled(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$GalleryWorkspaceKindEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$GalleryInstallResultInstalledToJson(
  GalleryInstallResultInstalled instance,
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
