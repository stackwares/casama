// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_reactions.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageReactionsCWProxy {
  MessageReactions messageId(String messageId);

  MessageReactions reactions(List<ReactionSummary> reactions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageReactions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageReactions(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageReactions call({String messageId, List<ReactionSummary> reactions});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageReactions.copyWith(...)` or call `instanceOfMessageReactions.copyWith.fieldName(value)` for a single field.
class _$MessageReactionsCWProxyImpl implements _$MessageReactionsCWProxy {
  const _$MessageReactionsCWProxyImpl(this._value);

  final MessageReactions _value;

  @override
  MessageReactions messageId(String messageId) => call(messageId: messageId);

  @override
  MessageReactions reactions(List<ReactionSummary> reactions) =>
      call(reactions: reactions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageReactions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageReactions(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageReactions call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? reactions = const $CopyWithPlaceholder(),
  }) {
    return MessageReactions(
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      reactions: reactions == const $CopyWithPlaceholder() || reactions == null
          ? _value.reactions
          // ignore: cast_nullable_to_non_nullable
          : reactions as List<ReactionSummary>,
    );
  }
}

extension $MessageReactionsCopyWith on MessageReactions {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageReactions.copyWith(...)` or `instanceOfMessageReactions.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageReactionsCWProxy get copyWith => _$MessageReactionsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageReactions _$MessageReactionsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MessageReactions', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['message_id', 'reactions']);
      final val = MessageReactions(
        messageId: $checkedConvert('message_id', (v) => v as String),
        reactions: $checkedConvert(
          'reactions',
          (v) => (v as List<dynamic>)
              .map((e) => ReactionSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'messageId': 'message_id'});

Map<String, dynamic> _$MessageReactionsToJson(MessageReactions instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'reactions': instance.reactions.map((e) => e.toJson()).toList(),
    };
