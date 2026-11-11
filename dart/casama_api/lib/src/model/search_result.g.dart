// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchResultCWProxy {
  SearchResult kind(SearchKind kind);

  SearchResult id(String id);

  SearchResult title(String title);

  SearchResult snippet(String snippet);

  SearchResult botId(String? botId);

  SearchResult conversationId(String? conversationId);

  SearchResult createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SearchResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SearchResult(...).copyWith(id: 12, name: "My name")
  /// ```
  SearchResult call({
    SearchKind kind,
    String id,
    String title,
    String snippet,
    String? botId,
    String? conversationId,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSearchResult.copyWith(...)` or call `instanceOfSearchResult.copyWith.fieldName(value)` for a single field.
class _$SearchResultCWProxyImpl implements _$SearchResultCWProxy {
  const _$SearchResultCWProxyImpl(this._value);

  final SearchResult _value;

  @override
  SearchResult kind(SearchKind kind) => call(kind: kind);

  @override
  SearchResult id(String id) => call(id: id);

  @override
  SearchResult title(String title) => call(title: title);

  @override
  SearchResult snippet(String snippet) => call(snippet: snippet);

  @override
  SearchResult botId(String? botId) => call(botId: botId);

  @override
  SearchResult conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  SearchResult createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SearchResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SearchResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SearchResult call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? snippet = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return SearchResult(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as SearchKind,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      snippet: snippet == const $CopyWithPlaceholder() || snippet == null
          ? _value.snippet
          // ignore: cast_nullable_to_non_nullable
          : snippet as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SearchResultCopyWith on SearchResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSearchResult.copyWith(...)` or `instanceOfSearchResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchResultCWProxy get copyWith => _$SearchResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResult _$SearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SearchResult',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'kind',
        'id',
        'title',
        'snippet',
        'bot_id',
        'conversation_id',
        'created_at',
      ],
    );
    final val = SearchResult(
      kind: $checkedConvert('kind', (v) => $enumDecode(_$SearchKindEnumMap, v)),
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      snippet: $checkedConvert('snippet', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'conversationId': 'conversation_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) =>
    <String, dynamic>{
      'kind': _$SearchKindEnumMap[instance.kind]!,
      'id': instance.id,
      'title': instance.title,
      'snippet': instance.snippet,
      'bot_id': instance.botId,
      'conversation_id': instance.conversationId,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$SearchKindEnumMap = {
  SearchKind.message: 'message',
  SearchKind.chat: 'chat',
  SearchKind.memory: 'memory',
  SearchKind.skill: 'skill',
  SearchKind.routine: 'routine',
  SearchKind.ticket: 'ticket',
};
