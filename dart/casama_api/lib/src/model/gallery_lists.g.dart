// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_lists.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GalleryListsCWProxy {
  GalleryLists searchWords(Map<String, List<String>>? searchWords);

  GalleryLists starters(GalleryListsStarters? starters);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryLists(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryLists(...).copyWith(id: 12, name: "My name")
  /// ```
  GalleryLists call({
    Map<String, List<String>>? searchWords,
    GalleryListsStarters? starters,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGalleryLists.copyWith(...)` or call `instanceOfGalleryLists.copyWith.fieldName(value)` for a single field.
class _$GalleryListsCWProxyImpl implements _$GalleryListsCWProxy {
  const _$GalleryListsCWProxyImpl(this._value);

  final GalleryLists _value;

  @override
  GalleryLists searchWords(Map<String, List<String>>? searchWords) =>
      call(searchWords: searchWords);

  @override
  GalleryLists starters(GalleryListsStarters? starters) =>
      call(starters: starters);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GalleryLists(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GalleryLists(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GalleryLists call({
    Object? searchWords = const $CopyWithPlaceholder(),
    Object? starters = const $CopyWithPlaceholder(),
  }) {
    return GalleryLists(
      searchWords: searchWords == const $CopyWithPlaceholder()
          ? _value.searchWords
          // ignore: cast_nullable_to_non_nullable
          : searchWords as Map<String, List<String>>?,
      starters: starters == const $CopyWithPlaceholder()
          ? _value.starters
          // ignore: cast_nullable_to_non_nullable
          : starters as GalleryListsStarters?,
    );
  }
}

extension $GalleryListsCopyWith on GalleryLists {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGalleryLists.copyWith(...)` or `instanceOfGalleryLists.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GalleryListsCWProxy get copyWith => _$GalleryListsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryLists _$GalleryListsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GalleryLists', json, ($checkedConvert) {
      final val = GalleryLists(
        searchWords: $checkedConvert(
          'search_words',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ),
        ),
        starters: $checkedConvert(
          'starters',
          (v) => v == null
              ? null
              : GalleryListsStarters.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'searchWords': 'search_words'});

Map<String, dynamic> _$GalleryListsToJson(GalleryLists instance) =>
    <String, dynamic>{
      'search_words': ?instance.searchWords,
      'starters': ?instance.starters?.toJson(),
    };
