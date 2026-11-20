// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_entry_items_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasEntryItemsInnerCWProxy {
  CanvasEntryItemsInner text(String text);

  CanvasEntryItemsInner done(bool done);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasEntryItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasEntryItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasEntryItemsInner call({String text, bool done});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasEntryItemsInner.copyWith(...)` or call `instanceOfCanvasEntryItemsInner.copyWith.fieldName(value)` for a single field.
class _$CanvasEntryItemsInnerCWProxyImpl
    implements _$CanvasEntryItemsInnerCWProxy {
  const _$CanvasEntryItemsInnerCWProxyImpl(this._value);

  final CanvasEntryItemsInner _value;

  @override
  CanvasEntryItemsInner text(String text) => call(text: text);

  @override
  CanvasEntryItemsInner done(bool done) => call(done: done);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasEntryItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasEntryItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasEntryItemsInner call({
    Object? text = const $CopyWithPlaceholder(),
    Object? done = const $CopyWithPlaceholder(),
  }) {
    return CanvasEntryItemsInner(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      done: done == const $CopyWithPlaceholder() || done == null
          ? _value.done
          // ignore: cast_nullable_to_non_nullable
          : done as bool,
    );
  }
}

extension $CanvasEntryItemsInnerCopyWith on CanvasEntryItemsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasEntryItemsInner.copyWith(...)` or `instanceOfCanvasEntryItemsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasEntryItemsInnerCWProxy get copyWith =>
      _$CanvasEntryItemsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasEntryItemsInner _$CanvasEntryItemsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CanvasEntryItemsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['text', 'done']);
  final val = CanvasEntryItemsInner(
    text: $checkedConvert('text', (v) => v as String),
    done: $checkedConvert('done', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$CanvasEntryItemsInnerToJson(
  CanvasEntryItemsInner instance,
) => <String, dynamic>{'text': instance.text, 'done': instance.done};
