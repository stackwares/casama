// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_include_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackIncludePreviewCWProxy {
  PackIncludePreview type(String type);

  PackIncludePreview id(String? id);

  PackIncludePreview url(String? url);

  PackIncludePreview commit(String? commit);

  PackIncludePreview name(String name);

  PackIncludePreview found(bool found);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackIncludePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackIncludePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PackIncludePreview call({
    String type,
    String? id,
    String? url,
    String? commit,
    String name,
    bool found,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackIncludePreview.copyWith(...)` or call `instanceOfPackIncludePreview.copyWith.fieldName(value)` for a single field.
class _$PackIncludePreviewCWProxyImpl implements _$PackIncludePreviewCWProxy {
  const _$PackIncludePreviewCWProxyImpl(this._value);

  final PackIncludePreview _value;

  @override
  PackIncludePreview type(String type) => call(type: type);

  @override
  PackIncludePreview id(String? id) => call(id: id);

  @override
  PackIncludePreview url(String? url) => call(url: url);

  @override
  PackIncludePreview commit(String? commit) => call(commit: commit);

  @override
  PackIncludePreview name(String name) => call(name: name);

  @override
  PackIncludePreview found(bool found) => call(found: found);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackIncludePreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackIncludePreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackIncludePreview call({
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? found = const $CopyWithPlaceholder(),
  }) {
    return PackIncludePreview(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      found: found == const $CopyWithPlaceholder() || found == null
          ? _value.found
          // ignore: cast_nullable_to_non_nullable
          : found as bool,
    );
  }
}

extension $PackIncludePreviewCopyWith on PackIncludePreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackIncludePreview.copyWith(...)` or `instanceOfPackIncludePreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackIncludePreviewCWProxy get copyWith =>
      _$PackIncludePreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackIncludePreview _$PackIncludePreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackIncludePreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['type', 'id', 'url', 'commit', 'name', 'found'],
      );
      final val = PackIncludePreview(
        type: $checkedConvert('type', (v) => v as String),
        id: $checkedConvert('id', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String?),
        commit: $checkedConvert('commit', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
        found: $checkedConvert('found', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$PackIncludePreviewToJson(PackIncludePreview instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'url': instance.url,
      'commit': instance.commit,
      'name': instance.name,
      'found': instance.found,
    };
