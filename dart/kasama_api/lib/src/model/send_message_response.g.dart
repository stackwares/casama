// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SendMessageResponseCWProxy {
  SendMessageResponse messageId(String messageId);

  SendMessageResponse runId(String runId);

  SendMessageResponse conversationId(String conversationId);

  SendMessageResponse runIds(List<String>? runIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SendMessageResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SendMessageResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  SendMessageResponse call({
    String messageId,
    String runId,
    String conversationId,
    List<String>? runIds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSendMessageResponse.copyWith(...)` or call `instanceOfSendMessageResponse.copyWith.fieldName(value)` for a single field.
class _$SendMessageResponseCWProxyImpl implements _$SendMessageResponseCWProxy {
  const _$SendMessageResponseCWProxyImpl(this._value);

  final SendMessageResponse _value;

  @override
  SendMessageResponse messageId(String messageId) => call(messageId: messageId);

  @override
  SendMessageResponse runId(String runId) => call(runId: runId);

  @override
  SendMessageResponse conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  SendMessageResponse runIds(List<String>? runIds) => call(runIds: runIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SendMessageResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SendMessageResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SendMessageResponse call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? runIds = const $CopyWithPlaceholder(),
  }) {
    return SendMessageResponse(
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      runIds: runIds == const $CopyWithPlaceholder()
          ? _value.runIds
          // ignore: cast_nullable_to_non_nullable
          : runIds as List<String>?,
    );
  }
}

extension $SendMessageResponseCopyWith on SendMessageResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSendMessageResponse.copyWith(...)` or `instanceOfSendMessageResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SendMessageResponseCWProxy get copyWith =>
      _$SendMessageResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendMessageResponse _$SendMessageResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SendMessageResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['message_id', 'run_id', 'conversation_id'],
        );
        final val = SendMessageResponse(
          messageId: $checkedConvert('message_id', (v) => v as String),
          runId: $checkedConvert('run_id', (v) => v as String),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String,
          ),
          runIds: $checkedConvert(
            'run_ids',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'messageId': 'message_id',
        'runId': 'run_id',
        'conversationId': 'conversation_id',
        'runIds': 'run_ids',
      },
    );

Map<String, dynamic> _$SendMessageResponseToJson(
  SendMessageResponse instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'run_id': instance.runId,
  'conversation_id': instance.conversationId,
  'run_ids': ?instance.runIds,
};
