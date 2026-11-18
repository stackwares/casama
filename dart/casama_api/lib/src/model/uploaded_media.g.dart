// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uploaded_media.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadedMediaCWProxy {
  UploadedMedia id(String id);

  UploadedMedia path(String path);

  UploadedMedia name(String name);

  UploadedMedia mimeType(String mimeType);

  UploadedMedia size(int size);

  UploadedMedia creationId(String? creationId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadedMedia(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadedMedia(...).copyWith(id: 12, name: "My name")
  /// ```
  UploadedMedia call({
    String id,
    String path,
    String name,
    String mimeType,
    int size,
    String? creationId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUploadedMedia.copyWith(...)` or call `instanceOfUploadedMedia.copyWith.fieldName(value)` for a single field.
class _$UploadedMediaCWProxyImpl implements _$UploadedMediaCWProxy {
  const _$UploadedMediaCWProxyImpl(this._value);

  final UploadedMedia _value;

  @override
  UploadedMedia id(String id) => call(id: id);

  @override
  UploadedMedia path(String path) => call(path: path);

  @override
  UploadedMedia name(String name) => call(name: name);

  @override
  UploadedMedia mimeType(String mimeType) => call(mimeType: mimeType);

  @override
  UploadedMedia size(int size) => call(size: size);

  @override
  UploadedMedia creationId(String? creationId) => call(creationId: creationId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadedMedia(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadedMedia(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UploadedMedia call({
    Object? id = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? mimeType = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? creationId = const $CopyWithPlaceholder(),
  }) {
    return UploadedMedia(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      mimeType: mimeType == const $CopyWithPlaceholder() || mimeType == null
          ? _value.mimeType
          // ignore: cast_nullable_to_non_nullable
          : mimeType as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
      creationId: creationId == const $CopyWithPlaceholder()
          ? _value.creationId
          // ignore: cast_nullable_to_non_nullable
          : creationId as String?,
    );
  }
}

extension $UploadedMediaCopyWith on UploadedMedia {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUploadedMedia.copyWith(...)` or `instanceOfUploadedMedia.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadedMediaCWProxy get copyWith => _$UploadedMediaCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadedMedia _$UploadedMediaFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'UploadedMedia',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'path',
            'name',
            'mime_type',
            'size',
            'creation_id',
          ],
        );
        final val = UploadedMedia(
          id: $checkedConvert('id', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          mimeType: $checkedConvert('mime_type', (v) => v as String),
          size: $checkedConvert('size', (v) => (v as num).toInt()),
          creationId: $checkedConvert('creation_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'mimeType': 'mime_type', 'creationId': 'creation_id'},
    );

Map<String, dynamic> _$UploadedMediaToJson(UploadedMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'name': instance.name,
      'mime_type': instance.mimeType,
      'size': instance.size,
      'creation_id': instance.creationId,
    };
