// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preview_plugin_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PreviewPluginRequestCWProxy {
  PreviewPluginRequest orgId(String orgId);

  PreviewPluginRequest url(String url);

  PreviewPluginRequest commit(String? commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PreviewPluginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PreviewPluginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PreviewPluginRequest call({String orgId, String url, String? commit});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPreviewPluginRequest.copyWith(...)` or call `instanceOfPreviewPluginRequest.copyWith.fieldName(value)` for a single field.
class _$PreviewPluginRequestCWProxyImpl
    implements _$PreviewPluginRequestCWProxy {
  const _$PreviewPluginRequestCWProxyImpl(this._value);

  final PreviewPluginRequest _value;

  @override
  PreviewPluginRequest orgId(String orgId) => call(orgId: orgId);

  @override
  PreviewPluginRequest url(String url) => call(url: url);

  @override
  PreviewPluginRequest commit(String? commit) => call(commit: commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PreviewPluginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PreviewPluginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PreviewPluginRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
  }) {
    return PreviewPluginRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
    );
  }
}

extension $PreviewPluginRequestCopyWith on PreviewPluginRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPreviewPluginRequest.copyWith(...)` or `instanceOfPreviewPluginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PreviewPluginRequestCWProxy get copyWith =>
      _$PreviewPluginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreviewPluginRequest _$PreviewPluginRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PreviewPluginRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'url']);
  final val = PreviewPluginRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    commit: $checkedConvert('commit', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$PreviewPluginRequestToJson(
  PreviewPluginRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'url': instance.url,
  'commit': ?instance.commit,
};
