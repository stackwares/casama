// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_trigger_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BrowserTriggerListCWProxy {
  BrowserTriggerList items(List<BrowserTriggerListItemsInner> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserTriggerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserTriggerList(...).copyWith(id: 12, name: "My name")
  /// ```
  BrowserTriggerList call({List<BrowserTriggerListItemsInner> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBrowserTriggerList.copyWith(...)` or call `instanceOfBrowserTriggerList.copyWith.fieldName(value)` for a single field.
class _$BrowserTriggerListCWProxyImpl implements _$BrowserTriggerListCWProxy {
  const _$BrowserTriggerListCWProxyImpl(this._value);

  final BrowserTriggerList _value;

  @override
  BrowserTriggerList items(List<BrowserTriggerListItemsInner> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BrowserTriggerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BrowserTriggerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BrowserTriggerList call({Object? items = const $CopyWithPlaceholder()}) {
    return BrowserTriggerList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BrowserTriggerListItemsInner>,
    );
  }
}

extension $BrowserTriggerListCopyWith on BrowserTriggerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBrowserTriggerList.copyWith(...)` or `instanceOfBrowserTriggerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BrowserTriggerListCWProxy get copyWith =>
      _$BrowserTriggerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrowserTriggerList _$BrowserTriggerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BrowserTriggerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = BrowserTriggerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => BrowserTriggerListItemsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BrowserTriggerListToJson(BrowserTriggerList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
