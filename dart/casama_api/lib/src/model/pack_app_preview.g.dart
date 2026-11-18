// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_app_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackAppPreviewCWProxy {
  PackAppPreview id(String id);

  PackAppPreview name(String name);

  PackAppPreview description(String description);

  PackAppPreview host(String host);

  PackAppPreview url(String url);

  PackAppPreview auth(List<String> auth);

  PackAppPreview capabilities(List<String> capabilities);

  PackAppPreview color(String color);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackAppPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackAppPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PackAppPreview call({
    String id,
    String name,
    String description,
    String host,
    String url,
    List<String> auth,
    List<String> capabilities,
    String color,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackAppPreview.copyWith(...)` or call `instanceOfPackAppPreview.copyWith.fieldName(value)` for a single field.
class _$PackAppPreviewCWProxyImpl implements _$PackAppPreviewCWProxy {
  const _$PackAppPreviewCWProxyImpl(this._value);

  final PackAppPreview _value;

  @override
  PackAppPreview id(String id) => call(id: id);

  @override
  PackAppPreview name(String name) => call(name: name);

  @override
  PackAppPreview description(String description) =>
      call(description: description);

  @override
  PackAppPreview host(String host) => call(host: host);

  @override
  PackAppPreview url(String url) => call(url: url);

  @override
  PackAppPreview auth(List<String> auth) => call(auth: auth);

  @override
  PackAppPreview capabilities(List<String> capabilities) =>
      call(capabilities: capabilities);

  @override
  PackAppPreview color(String color) => call(color: color);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackAppPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackAppPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackAppPreview call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? host = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? auth = const $CopyWithPlaceholder(),
    Object? capabilities = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
  }) {
    return PackAppPreview(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      host: host == const $CopyWithPlaceholder() || host == null
          ? _value.host
          // ignore: cast_nullable_to_non_nullable
          : host as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      auth: auth == const $CopyWithPlaceholder() || auth == null
          ? _value.auth
          // ignore: cast_nullable_to_non_nullable
          : auth as List<String>,
      capabilities:
          capabilities == const $CopyWithPlaceholder() || capabilities == null
          ? _value.capabilities
          // ignore: cast_nullable_to_non_nullable
          : capabilities as List<String>,
      color: color == const $CopyWithPlaceholder() || color == null
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
    );
  }
}

extension $PackAppPreviewCopyWith on PackAppPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackAppPreview.copyWith(...)` or `instanceOfPackAppPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackAppPreviewCWProxy get copyWith => _$PackAppPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackAppPreview _$PackAppPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackAppPreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'description',
          'host',
          'url',
          'auth',
          'capabilities',
          'color',
        ],
      );
      final val = PackAppPreview(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        host: $checkedConvert('host', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
        auth: $checkedConvert(
          'auth',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        capabilities: $checkedConvert(
          'capabilities',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        color: $checkedConvert('color', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PackAppPreviewToJson(PackAppPreview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'host': instance.host,
      'url': instance.url,
      'auth': instance.auth,
      'capabilities': instance.capabilities,
      'color': instance.color,
    };
