// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_gallery_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateGalleryRequestCWProxy {
  CreateGalleryRequest kind(GalleryKind kind);

  CreateGalleryRequest title(String title);

  CreateGalleryRequest details(String? details);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateGalleryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateGalleryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateGalleryRequest call({GalleryKind kind, String title, String? details});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateGalleryRequest.copyWith(...)` or call `instanceOfCreateGalleryRequest.copyWith.fieldName(value)` for a single field.
class _$CreateGalleryRequestCWProxyImpl
    implements _$CreateGalleryRequestCWProxy {
  const _$CreateGalleryRequestCWProxyImpl(this._value);

  final CreateGalleryRequest _value;

  @override
  CreateGalleryRequest kind(GalleryKind kind) => call(kind: kind);

  @override
  CreateGalleryRequest title(String title) => call(title: title);

  @override
  CreateGalleryRequest details(String? details) => call(details: details);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateGalleryRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateGalleryRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateGalleryRequest call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? details = const $CopyWithPlaceholder(),
  }) {
    return CreateGalleryRequest(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as GalleryKind,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      details: details == const $CopyWithPlaceholder()
          ? _value.details
          // ignore: cast_nullable_to_non_nullable
          : details as String?,
    );
  }
}

extension $CreateGalleryRequestCopyWith on CreateGalleryRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateGalleryRequest.copyWith(...)` or `instanceOfCreateGalleryRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateGalleryRequestCWProxy get copyWith =>
      _$CreateGalleryRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateGalleryRequest _$CreateGalleryRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateGalleryRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'title']);
  final val = CreateGalleryRequest(
    kind: $checkedConvert('kind', (v) => $enumDecode(_$GalleryKindEnumMap, v)),
    title: $checkedConvert('title', (v) => v as String),
    details: $checkedConvert('details', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$CreateGalleryRequestToJson(
  CreateGalleryRequest instance,
) => <String, dynamic>{
  'kind': _$GalleryKindEnumMap[instance.kind]!,
  'title': instance.title,
  'details': ?instance.details,
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
