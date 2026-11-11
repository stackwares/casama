// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_knowledge_source_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateKnowledgeSourceRequestCWProxy {
  CreateKnowledgeSourceRequest orgId(String orgId);

  CreateKnowledgeSourceRequest botId(String? botId);

  CreateKnowledgeSourceRequest kind(CreateKnowledgeSourceRequestKindEnum kind);

  CreateKnowledgeSourceRequest name(String name);

  CreateKnowledgeSourceRequest files(
    List<CreateKnowledgeSourceRequestFilesInner>? files,
  );

  CreateKnowledgeSourceRequest url(String? url);

  CreateKnowledgeSourceRequest maxPages(int? maxPages);

  CreateKnowledgeSourceRequest repoUrl(String? repoUrl);

  CreateKnowledgeSourceRequest integrationId(String? integrationId);

  CreateKnowledgeSourceRequest documents(
    List<CreateKnowledgeSourceRequestDocumentsInner>? documents,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateKnowledgeSourceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateKnowledgeSourceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateKnowledgeSourceRequest call({
    String orgId,
    String? botId,
    CreateKnowledgeSourceRequestKindEnum kind,
    String name,
    List<CreateKnowledgeSourceRequestFilesInner>? files,
    String? url,
    int? maxPages,
    String? repoUrl,
    String? integrationId,
    List<CreateKnowledgeSourceRequestDocumentsInner>? documents,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateKnowledgeSourceRequest.copyWith(...)` or call `instanceOfCreateKnowledgeSourceRequest.copyWith.fieldName(value)` for a single field.
class _$CreateKnowledgeSourceRequestCWProxyImpl
    implements _$CreateKnowledgeSourceRequestCWProxy {
  const _$CreateKnowledgeSourceRequestCWProxyImpl(this._value);

  final CreateKnowledgeSourceRequest _value;

  @override
  CreateKnowledgeSourceRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateKnowledgeSourceRequest botId(String? botId) => call(botId: botId);

  @override
  CreateKnowledgeSourceRequest kind(
    CreateKnowledgeSourceRequestKindEnum kind,
  ) => call(kind: kind);

  @override
  CreateKnowledgeSourceRequest name(String name) => call(name: name);

  @override
  CreateKnowledgeSourceRequest files(
    List<CreateKnowledgeSourceRequestFilesInner>? files,
  ) => call(files: files);

  @override
  CreateKnowledgeSourceRequest url(String? url) => call(url: url);

  @override
  CreateKnowledgeSourceRequest maxPages(int? maxPages) =>
      call(maxPages: maxPages);

  @override
  CreateKnowledgeSourceRequest repoUrl(String? repoUrl) =>
      call(repoUrl: repoUrl);

  @override
  CreateKnowledgeSourceRequest integrationId(String? integrationId) =>
      call(integrationId: integrationId);

  @override
  CreateKnowledgeSourceRequest documents(
    List<CreateKnowledgeSourceRequestDocumentsInner>? documents,
  ) => call(documents: documents);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateKnowledgeSourceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateKnowledgeSourceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateKnowledgeSourceRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? maxPages = const $CopyWithPlaceholder(),
    Object? repoUrl = const $CopyWithPlaceholder(),
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? documents = const $CopyWithPlaceholder(),
  }) {
    return CreateKnowledgeSourceRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as CreateKnowledgeSourceRequestKindEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<CreateKnowledgeSourceRequestFilesInner>?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      maxPages: maxPages == const $CopyWithPlaceholder()
          ? _value.maxPages
          // ignore: cast_nullable_to_non_nullable
          : maxPages as int?,
      repoUrl: repoUrl == const $CopyWithPlaceholder()
          ? _value.repoUrl
          // ignore: cast_nullable_to_non_nullable
          : repoUrl as String?,
      integrationId: integrationId == const $CopyWithPlaceholder()
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String?,
      documents: documents == const $CopyWithPlaceholder()
          ? _value.documents
          // ignore: cast_nullable_to_non_nullable
          : documents as List<CreateKnowledgeSourceRequestDocumentsInner>?,
    );
  }
}

extension $CreateKnowledgeSourceRequestCopyWith
    on CreateKnowledgeSourceRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateKnowledgeSourceRequest.copyWith(...)` or `instanceOfCreateKnowledgeSourceRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateKnowledgeSourceRequestCWProxy get copyWith =>
      _$CreateKnowledgeSourceRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateKnowledgeSourceRequest _$CreateKnowledgeSourceRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateKnowledgeSourceRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'kind', 'name']);
    final val = CreateKnowledgeSourceRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$CreateKnowledgeSourceRequestKindEnumEnumMap, v),
      ),
      name: $checkedConvert('name', (v) => v as String),
      files: $checkedConvert(
        'files',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => CreateKnowledgeSourceRequestFilesInner.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      url: $checkedConvert('url', (v) => v as String?),
      maxPages: $checkedConvert('max_pages', (v) => (v as num?)?.toInt()),
      repoUrl: $checkedConvert('repo_url', (v) => v as String?),
      integrationId: $checkedConvert('integration_id', (v) => v as String?),
      documents: $checkedConvert(
        'documents',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => CreateKnowledgeSourceRequestDocumentsInner.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'maxPages': 'max_pages',
    'repoUrl': 'repo_url',
    'integrationId': 'integration_id',
  },
);

Map<String, dynamic> _$CreateKnowledgeSourceRequestToJson(
  CreateKnowledgeSourceRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'bot_id': ?instance.botId,
  'kind': _$CreateKnowledgeSourceRequestKindEnumEnumMap[instance.kind]!,
  'name': instance.name,
  'files': ?instance.files?.map((e) => e.toJson()).toList(),
  'url': ?instance.url,
  'max_pages': ?instance.maxPages,
  'repo_url': ?instance.repoUrl,
  'integration_id': ?instance.integrationId,
  'documents': ?instance.documents?.map((e) => e.toJson()).toList(),
};

const _$CreateKnowledgeSourceRequestKindEnumEnumMap = {
  CreateKnowledgeSourceRequestKindEnum.upload: 'upload',
  CreateKnowledgeSourceRequestKindEnum.website: 'website',
  CreateKnowledgeSourceRequestKindEnum.github: 'github',
  CreateKnowledgeSourceRequestKindEnum.connection: 'connection',
};
