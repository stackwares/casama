// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_pack_contents.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryPackContentsCWProxy {
  GalleryPackContents bots(int bots);

  GalleryPackContents skills(int skills);

  GalleryPackContents routines(int routines);

  GalleryPackContents apps(int apps);

  GalleryPackContents looks(int looks);

  GalleryPackContents tools(int tools);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPackContents(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPackContents(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryPackContents call({
    int bots,
    int skills,
    int routines,
    int apps,
    int looks,
    int tools,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryPackContents.copyWith(...)` or call `instanceOfGalleryPackContents.copyWith.fieldName(value)` for a single field.
class _$GalleryPackContentsCWProxyImpl implements _$GalleryPackContentsCWProxy {
  const _$GalleryPackContentsCWProxyImpl(this._value);

  final GalleryPackContents _value;

  @override
  GalleryPackContents bots(int bots) => call(bots: bots);

  @override
  GalleryPackContents skills(int skills) => call(skills: skills);

  @override
  GalleryPackContents routines(int routines) => call(routines: routines);

  @override
  GalleryPackContents apps(int apps) => call(apps: apps);

  @override
  GalleryPackContents looks(int looks) => call(looks: looks);

  @override
  GalleryPackContents tools(int tools) => call(tools: tools);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryPackContents(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryPackContents(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryPackContents call({
    Object? bots = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? apps = const $CopyWithPlaceholder(),
    Object? looks = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
  }) {
    return GalleryPackContents(
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as int,
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as int,
      routines: routines == const $CopyWithPlaceholder() || routines == null
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as int,
      apps: apps == const $CopyWithPlaceholder() || apps == null
          ? _value.apps
          // ignore: cast_nullable_to_non_nullable
          : apps as int,
      looks: looks == const $CopyWithPlaceholder() || looks == null
          ? _value.looks
          // ignore: cast_nullable_to_non_nullable
          : looks as int,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as int,
    );
  }
}

extension $GalleryPackContentsCopyWith on GalleryPackContents {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryPackContents.copyWith(...)` or `instanceOfGalleryPackContents.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryPackContentsCWProxy get copyWith =>
      _$GalleryPackContentsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryPackContents _$GalleryPackContentsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryPackContents', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'bots',
          'skills',
          'routines',
          'apps',
          'looks',
          'tools',
        ],
      );
      final val = GalleryPackContents(
        bots: $checkedConvert('bots', (v) => (v as num).toInt()),
        skills: $checkedConvert('skills', (v) => (v as num).toInt()),
        routines: $checkedConvert('routines', (v) => (v as num).toInt()),
        apps: $checkedConvert('apps', (v) => (v as num).toInt()),
        looks: $checkedConvert('looks', (v) => (v as num).toInt()),
        tools: $checkedConvert('tools', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$GalleryPackContentsToJson(
  GalleryPackContents instance,
) => <String, dynamic>{
  'bots': instance.bots,
  'skills': instance.skills,
  'routines': instance.routines,
  'apps': instance.apps,
  'looks': instance.looks,
  'tools': instance.tools,
};
