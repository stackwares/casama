// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_export.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackExportCWProxy {
  PackExport name(String name);

  PackExport files(List<PackExportFile> files);

  PackExport findings(List<PackSecretFinding> findings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackExport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackExport(...).copyWith(id: 12, name: "My name")
  /// ```
  PackExport call({
    String name,
    List<PackExportFile> files,
    List<PackSecretFinding> findings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackExport.copyWith(...)` or call `instanceOfPackExport.copyWith.fieldName(value)` for a single field.
class _$PackExportCWProxyImpl implements _$PackExportCWProxy {
  const _$PackExportCWProxyImpl(this._value);

  final PackExport _value;

  @override
  PackExport name(String name) => call(name: name);

  @override
  PackExport files(List<PackExportFile> files) => call(files: files);

  @override
  PackExport findings(List<PackSecretFinding> findings) =>
      call(findings: findings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackExport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackExport(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackExport call({
    Object? name = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? findings = const $CopyWithPlaceholder(),
  }) {
    return PackExport(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<PackExportFile>,
      findings: findings == const $CopyWithPlaceholder() || findings == null
          ? _value.findings
          // ignore: cast_nullable_to_non_nullable
          : findings as List<PackSecretFinding>,
    );
  }
}

extension $PackExportCopyWith on PackExport {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackExport.copyWith(...)` or `instanceOfPackExport.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackExportCWProxy get copyWith => _$PackExportCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackExport _$PackExportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackExport', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'files', 'findings']);
      final val = PackExport(
        name: $checkedConvert('name', (v) => v as String),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => PackExportFile.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        findings: $checkedConvert(
          'findings',
          (v) => (v as List<dynamic>)
              .map((e) => PackSecretFinding.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PackExportToJson(PackExport instance) =>
    <String, dynamic>{
      'name': instance.name,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'findings': instance.findings.map((e) => e.toJson()).toList(),
    };
