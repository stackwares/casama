// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_files_export_files_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceFilesExportFilesInnerCWProxy {
  WorkspaceFilesExportFilesInner path(String path);

  WorkspaceFilesExportFilesInner contentBase64(String contentBase64);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceFilesExportFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceFilesExportFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceFilesExportFilesInner call({String path, String contentBase64});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceFilesExportFilesInner.copyWith(...)` or call `instanceOfWorkspaceFilesExportFilesInner.copyWith.fieldName(value)` for a single field.
class _$WorkspaceFilesExportFilesInnerCWProxyImpl
    implements _$WorkspaceFilesExportFilesInnerCWProxy {
  const _$WorkspaceFilesExportFilesInnerCWProxyImpl(this._value);

  final WorkspaceFilesExportFilesInner _value;

  @override
  WorkspaceFilesExportFilesInner path(String path) => call(path: path);

  @override
  WorkspaceFilesExportFilesInner contentBase64(String contentBase64) =>
      call(contentBase64: contentBase64);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceFilesExportFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceFilesExportFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceFilesExportFilesInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? contentBase64 = const $CopyWithPlaceholder(),
  }) {
    return WorkspaceFilesExportFilesInner(
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

extension $WorkspaceFilesExportFilesInnerCopyWith
    on WorkspaceFilesExportFilesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceFilesExportFilesInner.copyWith(...)` or `instanceOfWorkspaceFilesExportFilesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceFilesExportFilesInnerCWProxy get copyWith =>
      _$WorkspaceFilesExportFilesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceFilesExportFilesInner _$WorkspaceFilesExportFilesInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WorkspaceFilesExportFilesInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['path', 'content_base64']);
  final val = WorkspaceFilesExportFilesInner(
    path: $checkedConvert('path', (v) => v as String),
    contentBase64: $checkedConvert('content_base64', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'contentBase64': 'content_base64'});

Map<String, dynamic> _$WorkspaceFilesExportFilesInnerToJson(
  WorkspaceFilesExportFilesInner instance,
) => <String, dynamic>{
  'path': instance.path,
  'content_base64': instance.contentBase64,
};
