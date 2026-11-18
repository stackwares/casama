// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preview_pack_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PreviewPackRequestCWProxy {
  PreviewPackRequest orgId(String orgId);

  PreviewPackRequest url(String? url);

  PreviewPackRequest commit(String? commit);

  PreviewPackRequest galleryId(String? galleryId);

  PreviewPackRequest shareToken(String? shareToken);

  PreviewPackRequest files(List<PackFileInput>? files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PreviewPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PreviewPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PreviewPackRequest call({
    String orgId,
    String? url,
    String? commit,
    String? galleryId,
    String? shareToken,
    List<PackFileInput>? files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPreviewPackRequest.copyWith(...)` or call `instanceOfPreviewPackRequest.copyWith.fieldName(value)` for a single field.
class _$PreviewPackRequestCWProxyImpl implements _$PreviewPackRequestCWProxy {
  const _$PreviewPackRequestCWProxyImpl(this._value);

  final PreviewPackRequest _value;

  @override
  PreviewPackRequest orgId(String orgId) => call(orgId: orgId);

  @override
  PreviewPackRequest url(String? url) => call(url: url);

  @override
  PreviewPackRequest commit(String? commit) => call(commit: commit);

  @override
  PreviewPackRequest galleryId(String? galleryId) => call(galleryId: galleryId);

  @override
  PreviewPackRequest shareToken(String? shareToken) =>
      call(shareToken: shareToken);

  @override
  PreviewPackRequest files(List<PackFileInput>? files) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PreviewPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PreviewPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PreviewPackRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? galleryId = const $CopyWithPlaceholder(),
    Object? shareToken = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return PreviewPackRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
      galleryId: galleryId == const $CopyWithPlaceholder()
          ? _value.galleryId
          // ignore: cast_nullable_to_non_nullable
          : galleryId as String?,
      shareToken: shareToken == const $CopyWithPlaceholder()
          ? _value.shareToken
          // ignore: cast_nullable_to_non_nullable
          : shareToken as String?,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<PackFileInput>?,
    );
  }
}

extension $PreviewPackRequestCopyWith on PreviewPackRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPreviewPackRequest.copyWith(...)` or `instanceOfPreviewPackRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PreviewPackRequestCWProxy get copyWith =>
      _$PreviewPackRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreviewPackRequest _$PreviewPackRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PreviewPackRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['org_id']);
        final val = PreviewPackRequest(
          orgId: $checkedConvert('org_id', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String?),
          commit: $checkedConvert('commit', (v) => v as String?),
          galleryId: $checkedConvert('gallery_id', (v) => v as String?),
          shareToken: $checkedConvert('share_token', (v) => v as String?),
          files: $checkedConvert(
            'files',
            (v) => (v as List<dynamic>?)
                ?.map((e) => PackFileInput.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'galleryId': 'gallery_id',
        'shareToken': 'share_token',
      },
    );

Map<String, dynamic> _$PreviewPackRequestToJson(PreviewPackRequest instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'url': ?instance.url,
      'commit': ?instance.commit,
      'gallery_id': ?instance.galleryId,
      'share_token': ?instance.shareToken,
      'files': ?instance.files?.map((e) => e.toJson()).toList(),
    };
