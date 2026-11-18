// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackSourceCWProxy {
  PackSource kind(PackSourceKindEnum kind);

  PackSource repo(String? repo);

  PackSource path(String? path);

  PackSource url(String? url);

  PackSource galleryId(String? galleryId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackSource(...).copyWith(id: 12, name: "My name")
  /// ```
  PackSource call({
    PackSourceKindEnum kind,
    String? repo,
    String? path,
    String? url,
    String? galleryId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackSource.copyWith(...)` or call `instanceOfPackSource.copyWith.fieldName(value)` for a single field.
class _$PackSourceCWProxyImpl implements _$PackSourceCWProxy {
  const _$PackSourceCWProxyImpl(this._value);

  final PackSource _value;

  @override
  PackSource kind(PackSourceKindEnum kind) => call(kind: kind);

  @override
  PackSource repo(String? repo) => call(repo: repo);

  @override
  PackSource path(String? path) => call(path: path);

  @override
  PackSource url(String? url) => call(url: url);

  @override
  PackSource galleryId(String? galleryId) => call(galleryId: galleryId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackSource(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackSource call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? repo = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? galleryId = const $CopyWithPlaceholder(),
  }) {
    return PackSource(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PackSourceKindEnum,
      repo: repo == const $CopyWithPlaceholder()
          ? _value.repo
          // ignore: cast_nullable_to_non_nullable
          : repo as String?,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      galleryId: galleryId == const $CopyWithPlaceholder()
          ? _value.galleryId
          // ignore: cast_nullable_to_non_nullable
          : galleryId as String?,
    );
  }
}

extension $PackSourceCopyWith on PackSource {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackSource.copyWith(...)` or `instanceOfPackSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackSourceCWProxy get copyWith => _$PackSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackSource _$PackSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackSource', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['kind', 'repo', 'path', 'url', 'gallery_id'],
      );
      final val = PackSource(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$PackSourceKindEnumEnumMap, v),
        ),
        repo: $checkedConvert('repo', (v) => v as String?),
        path: $checkedConvert('path', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String?),
        galleryId: $checkedConvert('gallery_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'galleryId': 'gallery_id'});

Map<String, dynamic> _$PackSourceToJson(PackSource instance) =>
    <String, dynamic>{
      'kind': _$PackSourceKindEnumEnumMap[instance.kind]!,
      'repo': instance.repo,
      'path': instance.path,
      'url': instance.url,
      'gallery_id': instance.galleryId,
    };

const _$PackSourceKindEnumEnumMap = {
  PackSourceKindEnum.github: 'github',
  PackSourceKindEnum.gallery: 'gallery',
  PackSourceKindEnum.share: 'share',
  PackSourceKindEnum.upload: 'upload',
};
