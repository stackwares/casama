// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_knowledge_source_request_documents_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateKnowledgeSourceRequestDocumentsInnerCWProxy {
  CreateKnowledgeSourceRequestDocumentsInner tool(String tool);

  CreateKnowledgeSourceRequestDocumentsInner args(Map<String, Object?>? args);

  CreateKnowledgeSourceRequestDocumentsInner title(String title);

  CreateKnowledgeSourceRequestDocumentsInner url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateKnowledgeSourceRequestDocumentsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateKnowledgeSourceRequestDocumentsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateKnowledgeSourceRequestDocumentsInner call({
    String tool,
    Map<String, Object?>? args,
    String title,
    String? url,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateKnowledgeSourceRequestDocumentsInner.copyWith(...)` or call `instanceOfCreateKnowledgeSourceRequestDocumentsInner.copyWith.fieldName(value)` for a single field.
class _$CreateKnowledgeSourceRequestDocumentsInnerCWProxyImpl
    implements _$CreateKnowledgeSourceRequestDocumentsInnerCWProxy {
  const _$CreateKnowledgeSourceRequestDocumentsInnerCWProxyImpl(this._value);

  final CreateKnowledgeSourceRequestDocumentsInner _value;

  @override
  CreateKnowledgeSourceRequestDocumentsInner tool(String tool) =>
      call(tool: tool);

  @override
  CreateKnowledgeSourceRequestDocumentsInner args(Map<String, Object?>? args) =>
      call(args: args);

  @override
  CreateKnowledgeSourceRequestDocumentsInner title(String title) =>
      call(title: title);

  @override
  CreateKnowledgeSourceRequestDocumentsInner url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateKnowledgeSourceRequestDocumentsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateKnowledgeSourceRequestDocumentsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateKnowledgeSourceRequestDocumentsInner call({
    Object? tool = const $CopyWithPlaceholder(),
    Object? args = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return CreateKnowledgeSourceRequestDocumentsInner(
      tool: tool == const $CopyWithPlaceholder() || tool == null
          ? _value.tool
          // ignore: cast_nullable_to_non_nullable
          : tool as String,
      args: args == const $CopyWithPlaceholder()
          ? _value.args
          // ignore: cast_nullable_to_non_nullable
          : args as Map<String, Object?>?,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $CreateKnowledgeSourceRequestDocumentsInnerCopyWith
    on CreateKnowledgeSourceRequestDocumentsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateKnowledgeSourceRequestDocumentsInner.copyWith(...)` or `instanceOfCreateKnowledgeSourceRequestDocumentsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateKnowledgeSourceRequestDocumentsInnerCWProxy get copyWith =>
      _$CreateKnowledgeSourceRequestDocumentsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateKnowledgeSourceRequestDocumentsInner
_$CreateKnowledgeSourceRequestDocumentsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateKnowledgeSourceRequestDocumentsInner', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['tool', 'title']);
  final val = CreateKnowledgeSourceRequestDocumentsInner(
    tool: $checkedConvert('tool', (v) => v as String),
    args: $checkedConvert('args', (v) => v as Map<String, dynamic>?),
    title: $checkedConvert('title', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$CreateKnowledgeSourceRequestDocumentsInnerToJson(
  CreateKnowledgeSourceRequestDocumentsInner instance,
) => <String, dynamic>{
  'tool': instance.tool,
  'args': ?instance.args,
  'title': instance.title,
  'url': ?instance.url,
};
