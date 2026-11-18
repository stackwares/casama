// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_needs.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryNeedsCWProxy {
  GalleryNeeds apps(List<String>? apps);

  GalleryNeeds skills(List<String>? skills);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryNeeds(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryNeeds(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryNeeds call({List<String>? apps, List<String>? skills});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryNeeds.copyWith(...)` or call `instanceOfGalleryNeeds.copyWith.fieldName(value)` for a single field.
class _$GalleryNeedsCWProxyImpl implements _$GalleryNeedsCWProxy {
  const _$GalleryNeedsCWProxyImpl(this._value);

  final GalleryNeeds _value;

  @override
  GalleryNeeds apps(List<String>? apps) => call(apps: apps);

  @override
  GalleryNeeds skills(List<String>? skills) => call(skills: skills);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryNeeds(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryNeeds(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryNeeds call({
    Object? apps = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
  }) {
    return GalleryNeeds(
      apps: apps == const $CopyWithPlaceholder()
          ? _value.apps
          // ignore: cast_nullable_to_non_nullable
          : apps as List<String>?,
      skills: skills == const $CopyWithPlaceholder()
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<String>?,
    );
  }
}

extension $GalleryNeedsCopyWith on GalleryNeeds {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryNeeds.copyWith(...)` or `instanceOfGalleryNeeds.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryNeedsCWProxy get copyWith => _$GalleryNeedsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryNeeds _$GalleryNeedsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryNeeds', json, ($checkedConvert) {
      final val = GalleryNeeds(
        apps: $checkedConvert(
          'apps',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        skills: $checkedConvert(
          'skills',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GalleryNeedsToJson(GalleryNeeds instance) =>
    <String, dynamic>{'apps': ?instance.apps, 'skills': ?instance.skills};
