// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_missing_apps_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryMissingAppsInnerCWProxy {
  GalleryMissingAppsInner id(String id);

  GalleryMissingAppsInner name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryMissingAppsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryMissingAppsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryMissingAppsInner call({String id, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryMissingAppsInner.copyWith(...)` or call `instanceOfGalleryMissingAppsInner.copyWith.fieldName(value)` for a single field.
class _$GalleryMissingAppsInnerCWProxyImpl
    implements _$GalleryMissingAppsInnerCWProxy {
  const _$GalleryMissingAppsInnerCWProxyImpl(this._value);

  final GalleryMissingAppsInner _value;

  @override
  GalleryMissingAppsInner id(String id) => call(id: id);

  @override
  GalleryMissingAppsInner name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryMissingAppsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryMissingAppsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryMissingAppsInner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return GalleryMissingAppsInner(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $GalleryMissingAppsInnerCopyWith on GalleryMissingAppsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryMissingAppsInner.copyWith(...)` or `instanceOfGalleryMissingAppsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryMissingAppsInnerCWProxy get copyWith =>
      _$GalleryMissingAppsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryMissingAppsInner _$GalleryMissingAppsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GalleryMissingAppsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'name']);
  final val = GalleryMissingAppsInner(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$GalleryMissingAppsInnerToJson(
  GalleryMissingAppsInner instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};
