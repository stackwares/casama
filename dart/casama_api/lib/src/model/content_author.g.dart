// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_author.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ContentAuthorCWProxy {
  ContentAuthor name(String name);

  ContentAuthor url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ContentAuthor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContentAuthor(...).copyWith(id: 12, name: "My name")
  /// ```
  ContentAuthor call({String name, String? url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfContentAuthor.copyWith(...)` or call `instanceOfContentAuthor.copyWith.fieldName(value)` for a single field.
class _$ContentAuthorCWProxyImpl implements _$ContentAuthorCWProxy {
  const _$ContentAuthorCWProxyImpl(this._value);

  final ContentAuthor _value;

  @override
  ContentAuthor name(String name) => call(name: name);

  @override
  ContentAuthor url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ContentAuthor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContentAuthor(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ContentAuthor call({
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return ContentAuthor(
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

extension $ContentAuthorCopyWith on ContentAuthor {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfContentAuthor.copyWith(...)` or `instanceOfContentAuthor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ContentAuthorCWProxy get copyWith => _$ContentAuthorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentAuthor _$ContentAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ContentAuthor', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = ContentAuthor(
        name: $checkedConvert('name', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ContentAuthorToJson(ContentAuthor instance) =>
    <String, dynamic>{'name': instance.name, 'url': ?instance.url};
