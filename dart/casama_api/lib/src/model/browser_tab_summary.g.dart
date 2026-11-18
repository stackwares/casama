// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_tab_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BrowserTabSummaryCWProxy {
  BrowserTabSummary type(BrowserTabSummaryTypeEnum type);

  BrowserTabSummary url(String url);

  BrowserTabSummary title(String title);

  BrowserTabSummary selection(String? selection);

  BrowserTabSummary text(String? text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserTabSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserTabSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  BrowserTabSummary call({
    BrowserTabSummaryTypeEnum type,
    String url,
    String title,
    String? selection,
    String? text,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBrowserTabSummary.copyWith(...)` or call `instanceOfBrowserTabSummary.copyWith.fieldName(value)` for a single field.
class _$BrowserTabSummaryCWProxyImpl implements _$BrowserTabSummaryCWProxy {
  const _$BrowserTabSummaryCWProxyImpl(this._value);

  final BrowserTabSummary _value;

  @override
  BrowserTabSummary type(BrowserTabSummaryTypeEnum type) => call(type: type);

  @override
  BrowserTabSummary url(String url) => call(url: url);

  @override
  BrowserTabSummary title(String title) => call(title: title);

  @override
  BrowserTabSummary selection(String? selection) => call(selection: selection);

  @override
  BrowserTabSummary text(String? text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserTabSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserTabSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BrowserTabSummary call({
    Object? type = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? selection = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return BrowserTabSummary(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as BrowserTabSummaryTypeEnum,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      selection: selection == const $CopyWithPlaceholder()
          ? _value.selection
          // ignore: cast_nullable_to_non_nullable
          : selection as String?,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
    );
  }
}

extension $BrowserTabSummaryCopyWith on BrowserTabSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBrowserTabSummary.copyWith(...)` or `instanceOfBrowserTabSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BrowserTabSummaryCWProxy get copyWith =>
      _$BrowserTabSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrowserTabSummary _$BrowserTabSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BrowserTabSummary', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['type', 'url', 'title']);
      final val = BrowserTabSummary(
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$BrowserTabSummaryTypeEnumEnumMap, v),
        ),
        url: $checkedConvert('url', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        selection: $checkedConvert('selection', (v) => v as String?),
        text: $checkedConvert('text', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$BrowserTabSummaryToJson(BrowserTabSummary instance) =>
    <String, dynamic>{
      'type': _$BrowserTabSummaryTypeEnumEnumMap[instance.type]!,
      'url': instance.url,
      'title': instance.title,
      'selection': ?instance.selection,
      'text': ?instance.text,
    };

const _$BrowserTabSummaryTypeEnumEnumMap = {
  BrowserTabSummaryTypeEnum.tab: 'tab',
};
