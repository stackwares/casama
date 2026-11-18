// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_history.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageHistoryCWProxy {
  PageHistory conversations(List<PageHistoryConversationsInner> conversations);

  PageHistory highlights(List<Highlight> highlights);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageHistory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageHistory(...).copyWith(id: 12, name: "My name")
  /// ```
  PageHistory call({
    List<PageHistoryConversationsInner> conversations,
    List<Highlight> highlights,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageHistory.copyWith(...)` or call `instanceOfPageHistory.copyWith.fieldName(value)` for a single field.
class _$PageHistoryCWProxyImpl implements _$PageHistoryCWProxy {
  const _$PageHistoryCWProxyImpl(this._value);

  final PageHistory _value;

  @override
  PageHistory conversations(
    List<PageHistoryConversationsInner> conversations,
  ) => call(conversations: conversations);

  @override
  PageHistory highlights(List<Highlight> highlights) =>
      call(highlights: highlights);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageHistory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageHistory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageHistory call({
    Object? conversations = const $CopyWithPlaceholder(),
    Object? highlights = const $CopyWithPlaceholder(),
  }) {
    return PageHistory(
      conversations:
          conversations == const $CopyWithPlaceholder() || conversations == null
          ? _value.conversations
          // ignore: cast_nullable_to_non_nullable
          : conversations as List<PageHistoryConversationsInner>,
      highlights:
          highlights == const $CopyWithPlaceholder() || highlights == null
          ? _value.highlights
          // ignore: cast_nullable_to_non_nullable
          : highlights as List<Highlight>,
    );
  }
}

extension $PageHistoryCopyWith on PageHistory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageHistory.copyWith(...)` or `instanceOfPageHistory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageHistoryCWProxy get copyWith => _$PageHistoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageHistory _$PageHistoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PageHistory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['conversations', 'highlights']);
      final val = PageHistory(
        conversations: $checkedConvert(
          'conversations',
          (v) => (v as List<dynamic>)
              .map(
                (e) => PageHistoryConversationsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        highlights: $checkedConvert(
          'highlights',
          (v) => (v as List<dynamic>)
              .map((e) => Highlight.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PageHistoryToJson(PageHistory instance) =>
    <String, dynamic>{
      'conversations': instance.conversations.map((e) => e.toJson()).toList(),
      'highlights': instance.highlights.map((e) => e.toJson()).toList(),
    };
