// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_files_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WorkspaceFilesResultCWProxy {
  WorkspaceFilesResult created(List<String> created);

  WorkspaceFilesResult updated(List<String> updated);

  WorkspaceFilesResult deleted(List<String> deleted);

  WorkspaceFilesResult unchanged(int unchanged);

  WorkspaceFilesResult errors(List<String> errors);

  WorkspaceFilesResult dryRun(bool dryRun);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceFilesResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceFilesResult(...).copyWith(id: 12, name: "My name")
  /// ```
  WorkspaceFilesResult call({
    List<String> created,
    List<String> updated,
    List<String> deleted,
    int unchanged,
    List<String> errors,
    bool dryRun,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWorkspaceFilesResult.copyWith(...)` or call `instanceOfWorkspaceFilesResult.copyWith.fieldName(value)` for a single field.
class _$WorkspaceFilesResultCWProxyImpl
    implements _$WorkspaceFilesResultCWProxy {
  const _$WorkspaceFilesResultCWProxyImpl(this._value);

  final WorkspaceFilesResult _value;

  @override
  WorkspaceFilesResult created(List<String> created) => call(created: created);

  @override
  WorkspaceFilesResult updated(List<String> updated) => call(updated: updated);

  @override
  WorkspaceFilesResult deleted(List<String> deleted) => call(deleted: deleted);

  @override
  WorkspaceFilesResult unchanged(int unchanged) => call(unchanged: unchanged);

  @override
  WorkspaceFilesResult errors(List<String> errors) => call(errors: errors);

  @override
  WorkspaceFilesResult dryRun(bool dryRun) => call(dryRun: dryRun);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WorkspaceFilesResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WorkspaceFilesResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WorkspaceFilesResult call({
    Object? created = const $CopyWithPlaceholder(),
    Object? updated = const $CopyWithPlaceholder(),
    Object? deleted = const $CopyWithPlaceholder(),
    Object? unchanged = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
    Object? dryRun = const $CopyWithPlaceholder(),
  }) {
    return WorkspaceFilesResult(
      created: created == const $CopyWithPlaceholder() || created == null
          ? _value.created
          // ignore: cast_nullable_to_non_nullable
          : created as List<String>,
      updated: updated == const $CopyWithPlaceholder() || updated == null
          ? _value.updated
          // ignore: cast_nullable_to_non_nullable
          : updated as List<String>,
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as List<String>,
      unchanged: unchanged == const $CopyWithPlaceholder() || unchanged == null
          ? _value.unchanged
          // ignore: cast_nullable_to_non_nullable
          : unchanged as int,
      errors: errors == const $CopyWithPlaceholder() || errors == null
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as List<String>,
      dryRun: dryRun == const $CopyWithPlaceholder() || dryRun == null
          ? _value.dryRun
          // ignore: cast_nullable_to_non_nullable
          : dryRun as bool,
    );
  }
}

extension $WorkspaceFilesResultCopyWith on WorkspaceFilesResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWorkspaceFilesResult.copyWith(...)` or `instanceOfWorkspaceFilesResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WorkspaceFilesResultCWProxy get copyWith =>
      _$WorkspaceFilesResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceFilesResult _$WorkspaceFilesResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WorkspaceFilesResult', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'created',
      'updated',
      'deleted',
      'unchanged',
      'errors',
      'dry_run',
    ],
  );
  final val = WorkspaceFilesResult(
    created: $checkedConvert(
      'created',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    updated: $checkedConvert(
      'updated',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    deleted: $checkedConvert(
      'deleted',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    unchanged: $checkedConvert('unchanged', (v) => (v as num).toInt()),
    errors: $checkedConvert(
      'errors',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    dryRun: $checkedConvert('dry_run', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'dryRun': 'dry_run'});

Map<String, dynamic> _$WorkspaceFilesResultToJson(
  WorkspaceFilesResult instance,
) => <String, dynamic>{
  'created': instance.created,
  'updated': instance.updated,
  'deleted': instance.deleted,
  'unchanged': instance.unchanged,
  'errors': instance.errors,
  'dry_run': instance.dryRun,
};
