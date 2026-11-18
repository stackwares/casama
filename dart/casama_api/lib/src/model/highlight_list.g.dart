// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HighlightListCWProxy {
  HighlightList items(List<Highlight> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `HighlightList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// HighlightList(...).copyWith(id: 12, name: "My name")
  /// ```
  HighlightList call({List<Highlight> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfHighlightList.copyWith(...)` or call `instanceOfHighlightList.copyWith.fieldName(value)` for a single field.
class _$HighlightListCWProxyImpl implements _$HighlightListCWProxy {
  const _$HighlightListCWProxyImpl(this._value);

  final HighlightList _value;

  @override
  HighlightList items(List<Highlight> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `HighlightList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// HighlightList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  HighlightList call({Object? items = const $CopyWithPlaceholder()}) {
    return HighlightList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Highlight>,
    );
  }
}

extension $HighlightListCopyWith on HighlightList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfHighlightList.copyWith(...)` or `instanceOfHighlightList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HighlightListCWProxy get copyWith => _$HighlightListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HighlightList _$HighlightListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HighlightList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = HighlightList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Highlight.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HighlightListToJson(HighlightList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
