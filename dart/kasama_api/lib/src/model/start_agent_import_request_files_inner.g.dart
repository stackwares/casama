// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_agent_import_request_files_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StartAgentImportRequestFilesInnerCWProxy {
  StartAgentImportRequestFilesInner path(String path);

  StartAgentImportRequestFilesInner contentBase64(String contentBase64);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartAgentImportRequestFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartAgentImportRequestFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  StartAgentImportRequestFilesInner call({String path, String contentBase64});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStartAgentImportRequestFilesInner.copyWith(...)` or call `instanceOfStartAgentImportRequestFilesInner.copyWith.fieldName(value)` for a single field.
class _$StartAgentImportRequestFilesInnerCWProxyImpl
    implements _$StartAgentImportRequestFilesInnerCWProxy {
  const _$StartAgentImportRequestFilesInnerCWProxyImpl(this._value);

  final StartAgentImportRequestFilesInner _value;

  @override
  StartAgentImportRequestFilesInner path(String path) => call(path: path);

  @override
  StartAgentImportRequestFilesInner contentBase64(String contentBase64) =>
      call(contentBase64: contentBase64);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartAgentImportRequestFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartAgentImportRequestFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StartAgentImportRequestFilesInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? contentBase64 = const $CopyWithPlaceholder(),
  }) {
    return StartAgentImportRequestFilesInner(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      contentBase64:
          contentBase64 == const $CopyWithPlaceholder() || contentBase64 == null
          ? _value.contentBase64
          // ignore: cast_nullable_to_non_nullable
          : contentBase64 as String,
    );
  }
}

extension $StartAgentImportRequestFilesInnerCopyWith
    on StartAgentImportRequestFilesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStartAgentImportRequestFilesInner.copyWith(...)` or `instanceOfStartAgentImportRequestFilesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StartAgentImportRequestFilesInnerCWProxy get copyWith =>
      _$StartAgentImportRequestFilesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartAgentImportRequestFilesInner _$StartAgentImportRequestFilesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StartAgentImportRequestFilesInner', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['path', 'content_base64']);
  final val = StartAgentImportRequestFilesInner(
    path: $checkedConvert('path', (v) => v as String),
    contentBase64: $checkedConvert('content_base64', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'contentBase64': 'content_base64'});

Map<String, dynamic> _$StartAgentImportRequestFilesInnerToJson(
  StartAgentImportRequestFilesInner instance,
) => <String, dynamic>{
  'path': instance.path,
  'content_base64': instance.contentBase64,
};
