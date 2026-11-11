// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchResponseCWProxy {
  SearchResponse query(String query);

  SearchResponse items(List<SearchResult> items);

  SearchResponse files(List<FileSearchResult> files);

  SearchResponse filesSearched(int filesSearched);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SearchResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SearchResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  SearchResponse call({
    String query,
    List<SearchResult> items,
    List<FileSearchResult> files,
    int filesSearched,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSearchResponse.copyWith(...)` or call `instanceOfSearchResponse.copyWith.fieldName(value)` for a single field.
class _$SearchResponseCWProxyImpl implements _$SearchResponseCWProxy {
  const _$SearchResponseCWProxyImpl(this._value);

  final SearchResponse _value;

  @override
  SearchResponse query(String query) => call(query: query);

  @override
  SearchResponse items(List<SearchResult> items) => call(items: items);

  @override
  SearchResponse files(List<FileSearchResult> files) => call(files: files);

  @override
  SearchResponse filesSearched(int filesSearched) =>
      call(filesSearched: filesSearched);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SearchResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SearchResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SearchResponse call({
    Object? query = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? filesSearched = const $CopyWithPlaceholder(),
  }) {
    return SearchResponse(
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SearchResult>,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<FileSearchResult>,
      filesSearched:
          filesSearched == const $CopyWithPlaceholder() || filesSearched == null
          ? _value.filesSearched
          // ignore: cast_nullable_to_non_nullable
          : filesSearched as int,
    );
  }
}

extension $SearchResponseCopyWith on SearchResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSearchResponse.copyWith(...)` or `instanceOfSearchResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchResponseCWProxy get copyWith => _$SearchResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SearchResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['query', 'items', 'files', 'files_searched'],
      );
      final val = SearchResponse(
        query: $checkedConvert('query', (v) => v as String),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => FileSearchResult.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        filesSearched: $checkedConvert(
          'files_searched',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'filesSearched': 'files_searched'});

Map<String, dynamic> _$SearchResponseToJson(SearchResponse instance) =>
    <String, dynamic>{
      'query': instance.query,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'files': instance.files.map((e) => e.toJson()).toList(),
      'files_searched': instance.filesSearched,
    };
