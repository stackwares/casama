// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_preview_installed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackPreviewInstalledCWProxy {
  PackPreviewInstalled id(String id);

  PackPreviewInstalled version(String? version);

  PackPreviewInstalled commit(String? commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackPreviewInstalled(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackPreviewInstalled(...).copyWith(id: 12, name: "My name")
  /// ```
  PackPreviewInstalled call({String id, String? version, String? commit});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackPreviewInstalled.copyWith(...)` or call `instanceOfPackPreviewInstalled.copyWith.fieldName(value)` for a single field.
class _$PackPreviewInstalledCWProxyImpl
    implements _$PackPreviewInstalledCWProxy {
  const _$PackPreviewInstalledCWProxyImpl(this._value);

  final PackPreviewInstalled _value;

  @override
  PackPreviewInstalled id(String id) => call(id: id);

  @override
  PackPreviewInstalled version(String? version) => call(version: version);

  @override
  PackPreviewInstalled commit(String? commit) => call(commit: commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackPreviewInstalled(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackPreviewInstalled(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackPreviewInstalled call({
    Object? id = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
  }) {
    return PackPreviewInstalled(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String?,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
    );
  }
}

extension $PackPreviewInstalledCopyWith on PackPreviewInstalled {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackPreviewInstalled.copyWith(...)` or `instanceOfPackPreviewInstalled.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackPreviewInstalledCWProxy get copyWith =>
      _$PackPreviewInstalledCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackPreviewInstalled _$PackPreviewInstalledFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackPreviewInstalled', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'version', 'commit']);
  final val = PackPreviewInstalled(
    id: $checkedConvert('id', (v) => v as String),
    version: $checkedConvert('version', (v) => v as String?),
    commit: $checkedConvert('commit', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$PackPreviewInstalledToJson(
  PackPreviewInstalled instance,
) => <String, dynamic>{
  'id': instance.id,
  'version': instance.version,
  'commit': instance.commit,
};
