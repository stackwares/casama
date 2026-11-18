// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_set_install_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GallerySetInstallRequestCWProxy {
  GallerySetInstallRequest orgId(String orgId);

  GallerySetInstallRequest botId(String? botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetInstallRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetInstallRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GallerySetInstallRequest call({String orgId, String? botId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGallerySetInstallRequest.copyWith(...)` or call `instanceOfGallerySetInstallRequest.copyWith.fieldName(value)` for a single field.
class _$GallerySetInstallRequestCWProxyImpl
    implements _$GallerySetInstallRequestCWProxy {
  const _$GallerySetInstallRequestCWProxyImpl(this._value);

  final GallerySetInstallRequest _value;

  @override
  GallerySetInstallRequest orgId(String orgId) => call(orgId: orgId);

  @override
  GallerySetInstallRequest botId(String? botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GallerySetInstallRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GallerySetInstallRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GallerySetInstallRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return GallerySetInstallRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
    );
  }
}

extension $GallerySetInstallRequestCopyWith on GallerySetInstallRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGallerySetInstallRequest.copyWith(...)` or `instanceOfGallerySetInstallRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GallerySetInstallRequestCWProxy get copyWith =>
      _$GallerySetInstallRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GallerySetInstallRequest _$GallerySetInstallRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GallerySetInstallRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id']);
  final val = GallerySetInstallRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'botId': 'bot_id'});

Map<String, dynamic> _$GallerySetInstallRequestToJson(
  GallerySetInstallRequest instance,
) => <String, dynamic>{'org_id': instance.orgId, 'bot_id': ?instance.botId};
