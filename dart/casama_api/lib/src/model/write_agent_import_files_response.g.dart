// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_agent_import_files_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteAgentImportFilesResponseCWProxy {
  WriteAgentImportFilesResponse written(int written);

  WriteAgentImportFilesResponse folder(String folder);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WriteAgentImportFilesResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WriteAgentImportFilesResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  WriteAgentImportFilesResponse call({int written, String folder});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWriteAgentImportFilesResponse.copyWith(...)` or call `instanceOfWriteAgentImportFilesResponse.copyWith.fieldName(value)` for a single field.
class _$WriteAgentImportFilesResponseCWProxyImpl
    implements _$WriteAgentImportFilesResponseCWProxy {
  const _$WriteAgentImportFilesResponseCWProxyImpl(this._value);

  final WriteAgentImportFilesResponse _value;

  @override
  WriteAgentImportFilesResponse written(int written) => call(written: written);

  @override
  WriteAgentImportFilesResponse folder(String folder) => call(folder: folder);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WriteAgentImportFilesResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WriteAgentImportFilesResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WriteAgentImportFilesResponse call({
    Object? written = const $CopyWithPlaceholder(),
    Object? folder = const $CopyWithPlaceholder(),
  }) {
    return WriteAgentImportFilesResponse(
      written: written == const $CopyWithPlaceholder() || written == null
          ? _value.written
          // ignore: cast_nullable_to_non_nullable
          : written as int,
      folder: folder == const $CopyWithPlaceholder() || folder == null
          ? _value.folder
          // ignore: cast_nullable_to_non_nullable
          : folder as String,
    );
  }
}

extension $WriteAgentImportFilesResponseCopyWith
    on WriteAgentImportFilesResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWriteAgentImportFilesResponse.copyWith(...)` or `instanceOfWriteAgentImportFilesResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteAgentImportFilesResponseCWProxy get copyWith =>
      _$WriteAgentImportFilesResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteAgentImportFilesResponse _$WriteAgentImportFilesResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WriteAgentImportFilesResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['written', 'folder']);
  final val = WriteAgentImportFilesResponse(
    written: $checkedConvert('written', (v) => (v as num).toInt()),
    folder: $checkedConvert('folder', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$WriteAgentImportFilesResponseToJson(
  WriteAgentImportFilesResponse instance,
) => <String, dynamic>{'written': instance.written, 'folder': instance.folder};
