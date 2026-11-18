// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_missing.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryMissingCWProxy {
  GalleryMissing apps(List<GalleryMissingAppsInner> apps);

  GalleryMissing skills(List<GalleryMissingAppsInner> skills);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryMissing(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryMissing(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryMissing call({
    List<GalleryMissingAppsInner> apps,
    List<GalleryMissingAppsInner> skills,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryMissing.copyWith(...)` or call `instanceOfGalleryMissing.copyWith.fieldName(value)` for a single field.
class _$GalleryMissingCWProxyImpl implements _$GalleryMissingCWProxy {
  const _$GalleryMissingCWProxyImpl(this._value);

  final GalleryMissing _value;

  @override
  GalleryMissing apps(List<GalleryMissingAppsInner> apps) => call(apps: apps);

  @override
  GalleryMissing skills(List<GalleryMissingAppsInner> skills) =>
      call(skills: skills);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryMissing(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryMissing(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryMissing call({
    Object? apps = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
  }) {
    return GalleryMissing(
      apps: apps == const $CopyWithPlaceholder() || apps == null
          ? _value.apps
          // ignore: cast_nullable_to_non_nullable
          : apps as List<GalleryMissingAppsInner>,
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<GalleryMissingAppsInner>,
    );
  }
}

extension $GalleryMissingCopyWith on GalleryMissing {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryMissing.copyWith(...)` or `instanceOfGalleryMissing.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryMissingCWProxy get copyWith => _$GalleryMissingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryMissing _$GalleryMissingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryMissing', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['apps', 'skills']);
      final val = GalleryMissing(
        apps: $checkedConvert(
          'apps',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    GalleryMissingAppsInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        skills: $checkedConvert(
          'skills',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    GalleryMissingAppsInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryMissingToJson(GalleryMissing instance) =>
    <String, dynamic>{
      'apps': instance.apps.map((e) => e.toJson()).toList(),
      'skills': instance.skills.map((e) => e.toJson()).toList(),
    };
