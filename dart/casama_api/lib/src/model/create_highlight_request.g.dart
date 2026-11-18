// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_highlight_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateHighlightRequestCWProxy {
  CreateHighlightRequest orgId(String orgId);

  CreateHighlightRequest url(String url);

  CreateHighlightRequest title(String? title);

  CreateHighlightRequest text(String text);

  CreateHighlightRequest prefix(String? prefix);

  CreateHighlightRequest suffix(String? suffix);

  CreateHighlightRequest note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateHighlightRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateHighlightRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateHighlightRequest call({
    String orgId,
    String url,
    String? title,
    String text,
    String? prefix,
    String? suffix,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateHighlightRequest.copyWith(...)` or call `instanceOfCreateHighlightRequest.copyWith.fieldName(value)` for a single field.
class _$CreateHighlightRequestCWProxyImpl
    implements _$CreateHighlightRequestCWProxy {
  const _$CreateHighlightRequestCWProxyImpl(this._value);

  final CreateHighlightRequest _value;

  @override
  CreateHighlightRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateHighlightRequest url(String url) => call(url: url);

  @override
  CreateHighlightRequest title(String? title) => call(title: title);

  @override
  CreateHighlightRequest text(String text) => call(text: text);

  @override
  CreateHighlightRequest prefix(String? prefix) => call(prefix: prefix);

  @override
  CreateHighlightRequest suffix(String? suffix) => call(suffix: suffix);

  @override
  CreateHighlightRequest note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateHighlightRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateHighlightRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateHighlightRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? prefix = const $CopyWithPlaceholder(),
    Object? suffix = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return CreateHighlightRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      prefix: prefix == const $CopyWithPlaceholder()
          ? _value.prefix
          // ignore: cast_nullable_to_non_nullable
          : prefix as String?,
      suffix: suffix == const $CopyWithPlaceholder()
          ? _value.suffix
          // ignore: cast_nullable_to_non_nullable
          : suffix as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $CreateHighlightRequestCopyWith on CreateHighlightRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateHighlightRequest.copyWith(...)` or `instanceOfCreateHighlightRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateHighlightRequestCWProxy get copyWith =>
      _$CreateHighlightRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateHighlightRequest _$CreateHighlightRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateHighlightRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'url', 'text']);
  final val = CreateHighlightRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String?),
    text: $checkedConvert('text', (v) => v as String),
    prefix: $checkedConvert('prefix', (v) => v as String?),
    suffix: $checkedConvert('suffix', (v) => v as String?),
    note: $checkedConvert('note', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$CreateHighlightRequestToJson(
  CreateHighlightRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'url': instance.url,
  'title': ?instance.title,
  'text': instance.text,
  'prefix': ?instance.prefix,
  'suffix': ?instance.suffix,
  'note': ?instance.note,
};
