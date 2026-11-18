// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_bot_preview_knowledge_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackBotPreviewKnowledgeInnerCWProxy {
  PackBotPreviewKnowledgeInner kind(PackBotPreviewKnowledgeInnerKindEnum kind);

  PackBotPreviewKnowledgeInner name(String name);

  PackBotPreviewKnowledgeInner url(String url);

  PackBotPreviewKnowledgeInner maxPages(int maxPages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackBotPreviewKnowledgeInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackBotPreviewKnowledgeInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PackBotPreviewKnowledgeInner call({
    PackBotPreviewKnowledgeInnerKindEnum kind,
    String name,
    String url,
    int maxPages,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackBotPreviewKnowledgeInner.copyWith(...)` or call `instanceOfPackBotPreviewKnowledgeInner.copyWith.fieldName(value)` for a single field.
class _$PackBotPreviewKnowledgeInnerCWProxyImpl
    implements _$PackBotPreviewKnowledgeInnerCWProxy {
  const _$PackBotPreviewKnowledgeInnerCWProxyImpl(this._value);

  final PackBotPreviewKnowledgeInner _value;

  @override
  PackBotPreviewKnowledgeInner kind(
    PackBotPreviewKnowledgeInnerKindEnum kind,
  ) => call(kind: kind);

  @override
  PackBotPreviewKnowledgeInner name(String name) => call(name: name);

  @override
  PackBotPreviewKnowledgeInner url(String url) => call(url: url);

  @override
  PackBotPreviewKnowledgeInner maxPages(int maxPages) =>
      call(maxPages: maxPages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackBotPreviewKnowledgeInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackBotPreviewKnowledgeInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackBotPreviewKnowledgeInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? maxPages = const $CopyWithPlaceholder(),
  }) {
    return PackBotPreviewKnowledgeInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PackBotPreviewKnowledgeInnerKindEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      maxPages: maxPages == const $CopyWithPlaceholder() || maxPages == null
          ? _value.maxPages
          // ignore: cast_nullable_to_non_nullable
          : maxPages as int,
    );
  }
}

extension $PackBotPreviewKnowledgeInnerCopyWith
    on PackBotPreviewKnowledgeInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackBotPreviewKnowledgeInner.copyWith(...)` or `instanceOfPackBotPreviewKnowledgeInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackBotPreviewKnowledgeInnerCWProxy get copyWith =>
      _$PackBotPreviewKnowledgeInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackBotPreviewKnowledgeInner _$PackBotPreviewKnowledgeInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackBotPreviewKnowledgeInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'name', 'url', 'max_pages']);
  final val = PackBotPreviewKnowledgeInner(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$PackBotPreviewKnowledgeInnerKindEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    maxPages: $checkedConvert('max_pages', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'maxPages': 'max_pages'});

Map<String, dynamic> _$PackBotPreviewKnowledgeInnerToJson(
  PackBotPreviewKnowledgeInner instance,
) => <String, dynamic>{
  'kind': _$PackBotPreviewKnowledgeInnerKindEnumEnumMap[instance.kind]!,
  'name': instance.name,
  'url': instance.url,
  'max_pages': instance.maxPages,
};

const _$PackBotPreviewKnowledgeInnerKindEnumEnumMap = {
  PackBotPreviewKnowledgeInnerKindEnum.website: 'website',
  PackBotPreviewKnowledgeInnerKindEnum.github: 'github',
};
