// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_author.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TemplateAuthorCWProxy {
  TemplateAuthor name(String name);

  TemplateAuthor url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateAuthor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateAuthor(...).copyWith(id: 12, name: "My name")
  /// ```
  TemplateAuthor call({String name, String? url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTemplateAuthor.copyWith(...)` or call `instanceOfTemplateAuthor.copyWith.fieldName(value)` for a single field.
class _$TemplateAuthorCWProxyImpl implements _$TemplateAuthorCWProxy {
  const _$TemplateAuthorCWProxyImpl(this._value);

  final TemplateAuthor _value;

  @override
  TemplateAuthor name(String name) => call(name: name);

  @override
  TemplateAuthor url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TemplateAuthor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TemplateAuthor(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TemplateAuthor call({
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return TemplateAuthor(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $TemplateAuthorCopyWith on TemplateAuthor {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTemplateAuthor.copyWith(...)` or `instanceOfTemplateAuthor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TemplateAuthorCWProxy get copyWith => _$TemplateAuthorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateAuthor _$TemplateAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TemplateAuthor', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = TemplateAuthor(
        name: $checkedConvert('name', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$TemplateAuthorToJson(TemplateAuthor instance) =>
    <String, dynamic>{'name': instance.name, 'url': ?instance.url};
