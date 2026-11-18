// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_author_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryAuthorItemCWProxy {
  GalleryAuthorItem type(GalleryKind type);

  GalleryAuthorItem id(String id);

  GalleryAuthorItem name(String name);

  GalleryAuthorItem version(int? version);

  GalleryAuthorItem stats(GalleryAuthorItemStats stats);

  GalleryAuthorItem reportsOpen(int reportsOpen);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorItem(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryAuthorItem call({
    GalleryKind type,
    String id,
    String name,
    int? version,
    GalleryAuthorItemStats stats,
    int reportsOpen,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryAuthorItem.copyWith(...)` or call `instanceOfGalleryAuthorItem.copyWith.fieldName(value)` for a single field.
class _$GalleryAuthorItemCWProxyImpl implements _$GalleryAuthorItemCWProxy {
  const _$GalleryAuthorItemCWProxyImpl(this._value);

  final GalleryAuthorItem _value;

  @override
  GalleryAuthorItem type(GalleryKind type) => call(type: type);

  @override
  GalleryAuthorItem id(String id) => call(id: id);

  @override
  GalleryAuthorItem name(String name) => call(name: name);

  @override
  GalleryAuthorItem version(int? version) => call(version: version);

  @override
  GalleryAuthorItem stats(GalleryAuthorItemStats stats) => call(stats: stats);

  @override
  GalleryAuthorItem reportsOpen(int reportsOpen) =>
      call(reportsOpen: reportsOpen);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryAuthorItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryAuthorItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryAuthorItem call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? stats = const $CopyWithPlaceholder(),
    Object? reportsOpen = const $CopyWithPlaceholder(),
  }) {
    return GalleryAuthorItem(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GalleryKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int?,
      stats: stats == const $CopyWithPlaceholder() || stats == null
          ? _value.stats
          // ignore: cast_nullable_to_non_nullable
          : stats as GalleryAuthorItemStats,
      reportsOpen:
          reportsOpen == const $CopyWithPlaceholder() || reportsOpen == null
          ? _value.reportsOpen
          // ignore: cast_nullable_to_non_nullable
          : reportsOpen as int,
    );
  }
}

extension $GalleryAuthorItemCopyWith on GalleryAuthorItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryAuthorItem.copyWith(...)` or `instanceOfGalleryAuthorItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryAuthorItemCWProxy get copyWith =>
      _$GalleryAuthorItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryAuthorItem _$GalleryAuthorItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryAuthorItem', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'type',
          'id',
          'name',
          'version',
          'stats',
          'reports_open',
        ],
      );
      final val = GalleryAuthorItem(
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$GalleryKindEnumMap, v),
        ),
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        version: $checkedConvert('version', (v) => (v as num?)?.toInt()),
        stats: $checkedConvert(
          'stats',
          (v) => GalleryAuthorItemStats.fromJson(v as Map<String, dynamic>),
        ),
        reportsOpen: $checkedConvert('reports_open', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'reportsOpen': 'reports_open'});

Map<String, dynamic> _$GalleryAuthorItemToJson(GalleryAuthorItem instance) =>
    <String, dynamic>{
      'type': _$GalleryKindEnumMap[instance.type]!,
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
      'stats': instance.stats.toJson(),
      'reports_open': instance.reportsOpen,
    };

const _$GalleryKindEnumMap = {
  GalleryKind.theme: 'theme',
  GalleryKind.scheme: 'scheme',
  GalleryKind.wallpaper: 'wallpaper',
  GalleryKind.skill: 'skill',
  GalleryKind.app: 'app',
  GalleryKind.bot: 'bot',
  GalleryKind.routine: 'routine',
  GalleryKind.plugin: 'plugin',
};
