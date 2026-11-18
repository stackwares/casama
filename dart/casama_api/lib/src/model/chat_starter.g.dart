// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_starter.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChatStarterCWProxy {
  ChatStarter emoji(String emoji);

  ChatStarter text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  ChatStarter call({String emoji, String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChatStarter.copyWith(...)` or call `instanceOfChatStarter.copyWith.fieldName(value)` for a single field.
class _$ChatStarterCWProxyImpl implements _$ChatStarterCWProxy {
  const _$ChatStarterCWProxyImpl(this._value);

  final ChatStarter _value;

  @override
  ChatStarter emoji(String emoji) => call(emoji: emoji);

  @override
  ChatStarter text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatStarter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatStarter(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChatStarter call({
    Object? emoji = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return ChatStarter(
      emoji: emoji == const $CopyWithPlaceholder() || emoji == null
          ? _value.emoji
          // ignore: cast_nullable_to_non_nullable
          : emoji as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $ChatStarterCopyWith on ChatStarter {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChatStarter.copyWith(...)` or `instanceOfChatStarter.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChatStarterCWProxy get copyWith => _$ChatStarterCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatStarter _$ChatStarterFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChatStarter', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['emoji', 'text']);
      final val = ChatStarter(
        emoji: $checkedConvert('emoji', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ChatStarterToJson(ChatStarter instance) =>
    <String, dynamic>{'emoji': instance.emoji, 'text': instance.text};
