// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_gallery_submission.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateGallerySubmissionCWProxy {
  CreateGallerySubmission type(GallerySubmissionKind type);

  CreateGallerySubmission id(String? id);

  CreateGallerySubmission item(Map<String, Object?> item);

  CreateGallerySubmission files(Map<String, String> files);

  CreateGallerySubmission remixOf(GalleryRef? remixOf);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateGallerySubmission(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateGallerySubmission(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateGallerySubmission call({
    GallerySubmissionKind type,
    String? id,
    Map<String, Object?> item,
    Map<String, String> files,
    GalleryRef? remixOf,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateGallerySubmission.copyWith(...)` or call `instanceOfCreateGallerySubmission.copyWith.fieldName(value)` for a single field.
class _$CreateGallerySubmissionCWProxyImpl
    implements _$CreateGallerySubmissionCWProxy {
  const _$CreateGallerySubmissionCWProxyImpl(this._value);

  final CreateGallerySubmission _value;

  @override
  CreateGallerySubmission type(GallerySubmissionKind type) => call(type: type);

  @override
  CreateGallerySubmission id(String? id) => call(id: id);

  @override
  CreateGallerySubmission item(Map<String, Object?> item) => call(item: item);

  @override
  CreateGallerySubmission files(Map<String, String> files) =>
      call(files: files);

  @override
  CreateGallerySubmission remixOf(GalleryRef? remixOf) =>
      call(remixOf: remixOf);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateGallerySubmission(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateGallerySubmission(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateGallerySubmission call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? item = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? remixOf = const $CopyWithPlaceholder(),
  }) {
    return CreateGallerySubmission(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as GallerySubmissionKind,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String?,
      item: item == const $CopyWithPlaceholder() || item == null
          ? _value.item
          // ignore: cast_nullable_to_non_nullable
          : item as Map<String, Object?>,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as Map<String, String>,
      remixOf: remixOf == const $CopyWithPlaceholder()
          ? _value.remixOf
          // ignore: cast_nullable_to_non_nullable
          : remixOf as GalleryRef?,
    );
  }
}

extension $CreateGallerySubmissionCopyWith on CreateGallerySubmission {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateGallerySubmission.copyWith(...)` or `instanceOfCreateGallerySubmission.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateGallerySubmissionCWProxy get copyWith =>
      _$CreateGallerySubmissionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGallerySubmission _$CreateGallerySubmissionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateGallerySubmission', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['type', 'item', 'files']);
  final val = CreateGallerySubmission(
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$GallerySubmissionKindEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String?),
    item: $checkedConvert('item', (v) => v as Map<String, dynamic>),
    files: $checkedConvert('files', (v) => Map<String, String>.from(v as Map)),
    remixOf: $checkedConvert(
      'remix_of',
      (v) => v == null ? null : GalleryRef.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'remixOf': 'remix_of'});

Map<String, dynamic> _$CreateGallerySubmissionToJson(
  CreateGallerySubmission instance,
) => <String, dynamic>{
  'type': _$GallerySubmissionKindEnumMap[instance.type]!,
  'id': ?instance.id,
  'item': instance.item,
  'files': instance.files,
  'remix_of': ?instance.remixOf?.toJson(),
};

const _$GallerySubmissionKindEnumMap = {
  GallerySubmissionKind.theme: 'theme',
  GallerySubmissionKind.scheme: 'scheme',
  GallerySubmissionKind.wallpaper: 'wallpaper',
  GallerySubmissionKind.skill: 'skill',
  GallerySubmissionKind.routine: 'routine',
  GallerySubmissionKind.bot: 'bot',
};
