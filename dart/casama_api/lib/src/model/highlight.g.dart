// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HighlightCWProxy {
  Highlight id(String id);

  Highlight orgId(String orgId);

  Highlight url(String url);

  Highlight urlKey(String urlKey);

  Highlight title(String title);

  Highlight text(String text);

  Highlight prefix(String prefix);

  Highlight suffix(String suffix);

  Highlight note(String note);

  Highlight createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Highlight(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Highlight(...).copyWith(id: 12, name: "My name")
  /// ```
  Highlight call({
    String id,
    String orgId,
    String url,
    String urlKey,
    String title,
    String text,
    String prefix,
    String suffix,
    String note,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfHighlight.copyWith(...)` or call `instanceOfHighlight.copyWith.fieldName(value)` for a single field.
class _$HighlightCWProxyImpl implements _$HighlightCWProxy {
  const _$HighlightCWProxyImpl(this._value);

  final Highlight _value;

  @override
  Highlight id(String id) => call(id: id);

  @override
  Highlight orgId(String orgId) => call(orgId: orgId);

  @override
  Highlight url(String url) => call(url: url);

  @override
  Highlight urlKey(String urlKey) => call(urlKey: urlKey);

  @override
  Highlight title(String title) => call(title: title);

  @override
  Highlight text(String text) => call(text: text);

  @override
  Highlight prefix(String prefix) => call(prefix: prefix);

  @override
  Highlight suffix(String suffix) => call(suffix: suffix);

  @override
  Highlight note(String note) => call(note: note);

  @override
  Highlight createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Highlight(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Highlight(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Highlight call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? urlKey = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? prefix = const $CopyWithPlaceholder(),
    Object? suffix = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Highlight(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      urlKey: urlKey == const $CopyWithPlaceholder() || urlKey == null
          ? _value.urlKey
          // ignore: cast_nullable_to_non_nullable
          : urlKey as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      prefix: prefix == const $CopyWithPlaceholder() || prefix == null
          ? _value.prefix
          // ignore: cast_nullable_to_non_nullable
          : prefix as String,
      suffix: suffix == const $CopyWithPlaceholder() || suffix == null
          ? _value.suffix
          // ignore: cast_nullable_to_non_nullable
          : suffix as String,
      note: note == const $CopyWithPlaceholder() || note == null
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $HighlightCopyWith on Highlight {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfHighlight.copyWith(...)` or `instanceOfHighlight.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HighlightCWProxy get copyWith => _$HighlightCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Highlight _$HighlightFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Highlight',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'url',
        'url_key',
        'title',
        'text',
        'prefix',
        'suffix',
        'note',
        'created_at',
      ],
    );
    final val = Highlight(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      urlKey: $checkedConvert('url_key', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      text: $checkedConvert('text', (v) => v as String),
      prefix: $checkedConvert('prefix', (v) => v as String),
      suffix: $checkedConvert('suffix', (v) => v as String),
      note: $checkedConvert('note', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'urlKey': 'url_key',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$HighlightToJson(Highlight instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'url': instance.url,
  'url_key': instance.urlKey,
  'title': instance.title,
  'text': instance.text,
  'prefix': instance.prefix,
  'suffix': instance.suffix,
  'note': instance.note,
  'created_at': instance.createdAt.toIso8601String(),
};
