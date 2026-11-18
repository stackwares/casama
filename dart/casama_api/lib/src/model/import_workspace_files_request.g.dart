// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_workspace_files_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImportWorkspaceFilesRequestCWProxy {
  ImportWorkspaceFilesRequest zipBase64(String? zipBase64);

  ImportWorkspaceFilesRequest files(
    List<StartAgentImportRequestFilesInner>? files,
  );

  ImportWorkspaceFilesRequest dryRun(bool? dryRun);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportWorkspaceFilesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportWorkspaceFilesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ImportWorkspaceFilesRequest call({
    String? zipBase64,
    List<StartAgentImportRequestFilesInner>? files,
    bool? dryRun,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfImportWorkspaceFilesRequest.copyWith(...)` or call `instanceOfImportWorkspaceFilesRequest.copyWith.fieldName(value)` for a single field.
class _$ImportWorkspaceFilesRequestCWProxyImpl
    implements _$ImportWorkspaceFilesRequestCWProxy {
  const _$ImportWorkspaceFilesRequestCWProxyImpl(this._value);

  final ImportWorkspaceFilesRequest _value;

  @override
  ImportWorkspaceFilesRequest zipBase64(String? zipBase64) =>
      call(zipBase64: zipBase64);

  @override
  ImportWorkspaceFilesRequest files(
    List<StartAgentImportRequestFilesInner>? files,
  ) => call(files: files);

  @override
  ImportWorkspaceFilesRequest dryRun(bool? dryRun) => call(dryRun: dryRun);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ImportWorkspaceFilesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ImportWorkspaceFilesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ImportWorkspaceFilesRequest call({
    Object? zipBase64 = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? dryRun = const $CopyWithPlaceholder(),
  }) {
    return ImportWorkspaceFilesRequest(
      zipBase64: zipBase64 == const $CopyWithPlaceholder()
          ? _value.zipBase64
          // ignore: cast_nullable_to_non_nullable
          : zipBase64 as String?,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<StartAgentImportRequestFilesInner>?,
      dryRun: dryRun == const $CopyWithPlaceholder()
          ? _value.dryRun
          // ignore: cast_nullable_to_non_nullable
          : dryRun as bool?,
    );
  }
}

extension $ImportWorkspaceFilesRequestCopyWith on ImportWorkspaceFilesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfImportWorkspaceFilesRequest.copyWith(...)` or `instanceOfImportWorkspaceFilesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImportWorkspaceFilesRequestCWProxy get copyWith =>
      _$ImportWorkspaceFilesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportWorkspaceFilesRequest _$ImportWorkspaceFilesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ImportWorkspaceFilesRequest', json, ($checkedConvert) {
  final val = ImportWorkspaceFilesRequest(
    zipBase64: $checkedConvert('zip_base64', (v) => v as String?),
    files: $checkedConvert(
      'files',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => StartAgentImportRequestFilesInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    dryRun: $checkedConvert('dry_run', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'zipBase64': 'zip_base64', 'dryRun': 'dry_run'});

Map<String, dynamic> _$ImportWorkspaceFilesRequestToJson(
  ImportWorkspaceFilesRequest instance,
) => <String, dynamic>{
  'zip_base64': ?instance.zipBase64,
  'files': ?instance.files?.map((e) => e.toJson()).toList(),
  'dry_run': ?instance.dryRun,
};
