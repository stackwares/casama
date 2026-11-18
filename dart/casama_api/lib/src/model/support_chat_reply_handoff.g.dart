// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_chat_reply_handoff.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportChatReplyHandoffCWProxy {
  SupportChatReplyHandoff topic(SupportTopic topic);

  SupportChatReplyHandoff summary(String summary);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportChatReplyHandoff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportChatReplyHandoff(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportChatReplyHandoff call({SupportTopic topic, String summary});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportChatReplyHandoff.copyWith(...)` or call `instanceOfSupportChatReplyHandoff.copyWith.fieldName(value)` for a single field.
class _$SupportChatReplyHandoffCWProxyImpl
    implements _$SupportChatReplyHandoffCWProxy {
  const _$SupportChatReplyHandoffCWProxyImpl(this._value);

  final SupportChatReplyHandoff _value;

  @override
  SupportChatReplyHandoff topic(SupportTopic topic) => call(topic: topic);

  @override
  SupportChatReplyHandoff summary(String summary) => call(summary: summary);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportChatReplyHandoff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportChatReplyHandoff(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportChatReplyHandoff call({
    Object? topic = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
  }) {
    return SupportChatReplyHandoff(
      topic: topic == const $CopyWithPlaceholder() || topic == null
          ? _value.topic
          // ignore: cast_nullable_to_non_nullable
          : topic as SupportTopic,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
    );
  }
}

extension $SupportChatReplyHandoffCopyWith on SupportChatReplyHandoff {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportChatReplyHandoff.copyWith(...)` or `instanceOfSupportChatReplyHandoff.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportChatReplyHandoffCWProxy get copyWith =>
      _$SupportChatReplyHandoffCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportChatReplyHandoff _$SupportChatReplyHandoffFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SupportChatReplyHandoff', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['topic', 'summary']);
  final val = SupportChatReplyHandoff(
    topic: $checkedConvert(
      'topic',
      (v) => $enumDecode(_$SupportTopicEnumMap, v),
    ),
    summary: $checkedConvert('summary', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$SupportChatReplyHandoffToJson(
  SupportChatReplyHandoff instance,
) => <String, dynamic>{
  'topic': _$SupportTopicEnumMap[instance.topic]!,
  'summary': instance.summary,
};

const _$SupportTopicEnumMap = {
  SupportTopic.billing: 'billing',
  SupportTopic.broken: 'broken',
  SupportTopic.account: 'account',
  SupportTopic.question: 'question',
  SupportTopic.other: 'other',
};
