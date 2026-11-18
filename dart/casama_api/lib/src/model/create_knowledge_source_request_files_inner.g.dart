// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_knowledge_source_request_files_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateKnowledgeSourceRequestFilesInnerCWProxy {
  CreateKnowledgeSourceRequestFilesInner name(String name);

  CreateKnowledgeSourceRequestFilesInner contentBase64(String contentBase64);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateKnowledgeSourceRequestFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateKnowledgeSourceRequestFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateKnowledgeSourceRequestFilesInner call({
    String name,
    String contentBase64,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateKnowledgeSourceRequestFilesInner.copyWith(...)` or call `instanceOfCreateKnowledgeSourceRequestFilesInner.copyWith.fieldName(value)` for a single field.
class _$CreateKnowledgeSourceRequestFilesInnerCWProxyImpl
    implements _$CreateKnowledgeSourceRequestFilesInnerCWProxy {
  const _$CreateKnowledgeSourceRequestFilesInnerCWProxyImpl(this._value);

  final CreateKnowledgeSourceRequestFilesInner _value;

  @override
  CreateKnowledgeSourceRequestFilesInner name(String name) => call(name: name);

  @override
  CreateKnowledgeSourceRequestFilesInner contentBase64(String contentBase64) =>
      call(contentBase64: contentBase64);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateKnowledgeSourceRequestFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateKnowledgeSourceRequestFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateKnowledgeSourceRequestFilesInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? contentBase64 = const $CopyWithPlaceholder(),
  }) {
    return CreateKnowledgeSourceRequestFilesInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      contentBase64:
          contentBase64 == const $CopyWithPlaceholder() || contentBase64 == null
          ? _value.contentBase64
          // ignore: cast_nullable_to_non_nullable
          : contentBase64 as String,
    );
  }
}

extension $CreateKnowledgeSourceRequestFilesInnerCopyWith
    on CreateKnowledgeSourceRequestFilesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateKnowledgeSourceRequestFilesInner.copyWith(...)` or `instanceOfCreateKnowledgeSourceRequestFilesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateKnowledgeSourceRequestFilesInnerCWProxy get copyWith =>
      _$CreateKnowledgeSourceRequestFilesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateKnowledgeSourceRequestFilesInner
_$CreateKnowledgeSourceRequestFilesInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateKnowledgeSourceRequestFilesInner', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['name', 'content_base64']);
      final val = CreateKnowledgeSourceRequestFilesInner(
        name: $checkedConvert('name', (v) => v as String),
        contentBase64: $checkedConvert('content_base64', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'contentBase64': 'content_base64'});

Map<String, dynamic> _$CreateKnowledgeSourceRequestFilesInnerToJson(
  CreateKnowledgeSourceRequestFilesInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'content_base64': instance.contentBase64,
};
