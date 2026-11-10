// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_agent_import_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StartAgentImportRequestCWProxy {
  StartAgentImportRequest orgId(String orgId);

  StartAgentImportRequest zipBase64(String? zipBase64);

  StartAgentImportRequest files(List<StartAgentImportRequestFilesInner>? files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartAgentImportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartAgentImportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  StartAgentImportRequest call({
    String orgId,
    String? zipBase64,
    List<StartAgentImportRequestFilesInner>? files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStartAgentImportRequest.copyWith(...)` or call `instanceOfStartAgentImportRequest.copyWith.fieldName(value)` for a single field.
class _$StartAgentImportRequestCWProxyImpl
    implements _$StartAgentImportRequestCWProxy {
  const _$StartAgentImportRequestCWProxyImpl(this._value);

  final StartAgentImportRequest _value;

  @override
  StartAgentImportRequest orgId(String orgId) => call(orgId: orgId);

  @override
  StartAgentImportRequest zipBase64(String? zipBase64) =>
      call(zipBase64: zipBase64);

  @override
  StartAgentImportRequest files(
    List<StartAgentImportRequestFilesInner>? files,
  ) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StartAgentImportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StartAgentImportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StartAgentImportRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? zipBase64 = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return StartAgentImportRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      zipBase64: zipBase64 == const $CopyWithPlaceholder()
          ? _value.zipBase64
          // ignore: cast_nullable_to_non_nullable
          : zipBase64 as String?,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<StartAgentImportRequestFilesInner>?,
    );
  }
}

extension $StartAgentImportRequestCopyWith on StartAgentImportRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStartAgentImportRequest.copyWith(...)` or `instanceOfStartAgentImportRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StartAgentImportRequestCWProxy get copyWith =>
      _$StartAgentImportRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartAgentImportRequest _$StartAgentImportRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('StartAgentImportRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id']);
  final val = StartAgentImportRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
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
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'zipBase64': 'zip_base64'});

Map<String, dynamic> _$StartAgentImportRequestToJson(
  StartAgentImportRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'zip_base64': ?instance.zipBase64,
  'files': ?instance.files?.map((e) => e.toJson()).toList(),
};
