// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_trigger_list_items_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BrowserTriggerListItemsInnerCWProxy {
  BrowserTriggerListItemsInner event(
    BrowserTriggerListItemsInnerEventEnum event,
  );

  BrowserTriggerListItemsInner site(String? site);

  BrowserTriggerListItemsInner pattern(String? pattern);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserTriggerListItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserTriggerListItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  BrowserTriggerListItemsInner call({
    BrowserTriggerListItemsInnerEventEnum event,
    String? site,
    String? pattern,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBrowserTriggerListItemsInner.copyWith(...)` or call `instanceOfBrowserTriggerListItemsInner.copyWith.fieldName(value)` for a single field.
class _$BrowserTriggerListItemsInnerCWProxyImpl
    implements _$BrowserTriggerListItemsInnerCWProxy {
  const _$BrowserTriggerListItemsInnerCWProxyImpl(this._value);

  final BrowserTriggerListItemsInner _value;

  @override
  BrowserTriggerListItemsInner event(
    BrowserTriggerListItemsInnerEventEnum event,
  ) => call(event: event);

  @override
  BrowserTriggerListItemsInner site(String? site) => call(site: site);

  @override
  BrowserTriggerListItemsInner pattern(String? pattern) =>
      call(pattern: pattern);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserTriggerListItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserTriggerListItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BrowserTriggerListItemsInner call({
    Object? event = const $CopyWithPlaceholder(),
    Object? site = const $CopyWithPlaceholder(),
    Object? pattern = const $CopyWithPlaceholder(),
  }) {
    return BrowserTriggerListItemsInner(
      event: event == const $CopyWithPlaceholder() || event == null
          ? _value.event
          // ignore: cast_nullable_to_non_nullable
          : event as BrowserTriggerListItemsInnerEventEnum,
      site: site == const $CopyWithPlaceholder()
          ? _value.site
          // ignore: cast_nullable_to_non_nullable
          : site as String?,
      pattern: pattern == const $CopyWithPlaceholder()
          ? _value.pattern
          // ignore: cast_nullable_to_non_nullable
          : pattern as String?,
    );
  }
}

extension $BrowserTriggerListItemsInnerCopyWith
    on BrowserTriggerListItemsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBrowserTriggerListItemsInner.copyWith(...)` or `instanceOfBrowserTriggerListItemsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BrowserTriggerListItemsInnerCWProxy get copyWith =>
      _$BrowserTriggerListItemsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrowserTriggerListItemsInner _$BrowserTriggerListItemsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BrowserTriggerListItemsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['event']);
  final val = BrowserTriggerListItemsInner(
    event: $checkedConvert(
      'event',
      (v) => $enumDecode(_$BrowserTriggerListItemsInnerEventEnumEnumMap, v),
    ),
    site: $checkedConvert('site', (v) => v as String?),
    pattern: $checkedConvert('pattern', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$BrowserTriggerListItemsInnerToJson(
  BrowserTriggerListItemsInner instance,
) => <String, dynamic>{
  'event': _$BrowserTriggerListItemsInnerEventEnumEnumMap[instance.event]!,
  'site': ?instance.site,
  'pattern': ?instance.pattern,
};

const _$BrowserTriggerListItemsInnerEventEnumEnumMap = {
  BrowserTriggerListItemsInnerEventEnum.siteOpened: 'site_opened',
  BrowserTriggerListItemsInnerEventEnum.downloadDone: 'download_done',
  BrowserTriggerListItemsInnerEventEnum.bookmarkAdded: 'bookmark_added',
};
