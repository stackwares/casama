// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_files_export.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceFilesExportCWProxy {
  WorkspaceFilesExport zipBase64(String zipBase64);

  WorkspaceFilesExport count(int count);

  WorkspaceFilesExport files(List<WorkspaceFilesExportFilesInner> files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceFilesExport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceFilesExport(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceFilesExport call({
    String zipBase64,
    int count,
    List<WorkspaceFilesExportFilesInner> files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceFilesExport.copyWith(...)` or call `instanceOfWorkspaceFilesExport.copyWith.fieldName(value)` for a single field.
class _$WorkspaceFilesExportCWProxyImpl
    implements _$WorkspaceFilesExportCWProxy {
  const _$WorkspaceFilesExportCWProxyImpl(this._value);

  final WorkspaceFilesExport _value;

  @override
  WorkspaceFilesExport zipBase64(String zipBase64) =>
      call(zipBase64: zipBase64);

  @override
  WorkspaceFilesExport count(int count) => call(count: count);

  @override
  WorkspaceFilesExport files(List<WorkspaceFilesExportFilesInner> files) =>
      call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceFilesExport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceFilesExport(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceFilesExport call({
    Object? zipBase64 = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return WorkspaceFilesExport(
      zipBase64: zipBase64 == const $CopyWithPlaceholder() || zipBase64 == null
          ? _value.zipBase64
          // ignore: cast_nullable_to_non_nullable
          : zipBase64 as String,
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<WorkspaceFilesExportFilesInner>,
    );
  }
}

extension $WorkspaceFilesExportCopyWith on WorkspaceFilesExport {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceFilesExport.copyWith(...)` or `instanceOfWorkspaceFilesExport.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceFilesExportCWProxy get copyWith =>
      _$WorkspaceFilesExportCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceFilesExport _$WorkspaceFilesExportFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WorkspaceFilesExport', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['zip_base64', 'count', 'files']);
  final val = WorkspaceFilesExport(
    zipBase64: $checkedConvert('zip_base64', (v) => v as String),
    count: $checkedConvert('count', (v) => (v as num).toInt()),
    files: $checkedConvert(
      'files',
      (v) => (v as List<dynamic>)
          .map(
            (e) => WorkspaceFilesExportFilesInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'zipBase64': 'zip_base64'});

Map<String, dynamic> _$WorkspaceFilesExportToJson(
  WorkspaceFilesExport instance,
) => <String, dynamic>{
  'zip_base64': instance.zipBase64,
  'count': instance.count,
  'files': instance.files.map((e) => e.toJson()).toList(),
};
