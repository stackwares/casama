// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_install_result_missing.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackInstallResultMissingCWProxy {
  PackInstallResultMissing apps(List<GalleryMissingAppsInner> apps);

  PackInstallResultMissing skills(List<GalleryMissingAppsInner> skills);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackInstallResultMissing(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackInstallResultMissing(...).copyWith(id: 12, name: "My name")
  /// ```
  PackInstallResultMissing call({
    List<GalleryMissingAppsInner> apps,
    List<GalleryMissingAppsInner> skills,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackInstallResultMissing.copyWith(...)` or call `instanceOfPackInstallResultMissing.copyWith.fieldName(value)` for a single field.
class _$PackInstallResultMissingCWProxyImpl
    implements _$PackInstallResultMissingCWProxy {
  const _$PackInstallResultMissingCWProxyImpl(this._value);

  final PackInstallResultMissing _value;

  @override
  PackInstallResultMissing apps(List<GalleryMissingAppsInner> apps) =>
      call(apps: apps);

  @override
  PackInstallResultMissing skills(List<GalleryMissingAppsInner> skills) =>
      call(skills: skills);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackInstallResultMissing(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackInstallResultMissing(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackInstallResultMissing call({
    Object? apps = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
  }) {
    return PackInstallResultMissing(
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

extension $PackInstallResultMissingCopyWith on PackInstallResultMissing {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackInstallResultMissing.copyWith(...)` or `instanceOfPackInstallResultMissing.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackInstallResultMissingCWProxy get copyWith =>
      _$PackInstallResultMissingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackInstallResultMissing _$PackInstallResultMissingFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackInstallResultMissing', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['apps', 'skills']);
  final val = PackInstallResultMissing(
    apps: $checkedConvert(
      'apps',
      (v) => (v as List<dynamic>)
          .map(
            (e) => GalleryMissingAppsInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    skills: $checkedConvert(
      'skills',
      (v) => (v as List<dynamic>)
          .map(
            (e) => GalleryMissingAppsInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PackInstallResultMissingToJson(
  PackInstallResultMissing instance,
) => <String, dynamic>{
  'apps': instance.apps.map((e) => e.toJson()).toList(),
  'skills': instance.skills.map((e) => e.toJson()).toList(),
};
