// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_thread.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConversationThreadCWProxy {
  ConversationThread items(List<Map<String, Object?>> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConversationThread(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConversationThread(...).copyWith(id: 12, name: "My name")
  /// ```
  ConversationThread call({List<Map<String, Object?>> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConversationThread.copyWith(...)` or call `instanceOfConversationThread.copyWith.fieldName(value)` for a single field.
class _$ConversationThreadCWProxyImpl implements _$ConversationThreadCWProxy {
  const _$ConversationThreadCWProxyImpl(this._value);

  final ConversationThread _value;

  @override
  ConversationThread items(List<Map<String, Object?>> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConversationThread(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConversationThread(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConversationThread call({Object? items = const $CopyWithPlaceholder()}) {
    return ConversationThread(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Map<String, Object?>>,
    );
  }
}

extension $ConversationThreadCopyWith on ConversationThread {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConversationThread.copyWith(...)` or `instanceOfConversationThread.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConversationThreadCWProxy get copyWith =>
      _$ConversationThreadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationThread _$ConversationThreadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConversationThread', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ConversationThread(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ConversationThreadToJson(ConversationThread instance) =>
    <String, dynamic>{'items': instance.items};
