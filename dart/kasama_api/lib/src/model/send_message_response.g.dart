// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SendMessageResponseCWProxy {
  SendMessageResponse messageId(String messageId);

  SendMessageResponse runId(String runId);

  SendMessageResponse conversationId(String conversationId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SendMessageResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SendMessageResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  SendMessageResponse call({
    String messageId,
    String runId,
    String conversationId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSendMessageResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSendMessageResponse.copyWith.fieldName(...)`
class _$SendMessageResponseCWProxyImpl implements _$SendMessageResponseCWProxy {
  const _$SendMessageResponseCWProxyImpl(this._value);

  final SendMessageResponse _value;

  @override
  SendMessageResponse messageId(String messageId) => this(messageId: messageId);

  @override
  SendMessageResponse runId(String runId) => this(runId: runId);

  @override
  SendMessageResponse conversationId(String conversationId) =>
      this(conversationId: conversationId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SendMessageResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SendMessageResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  SendMessageResponse call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
  }) {
    return SendMessageResponse(
      messageId: messageId == const $CopyWithPlaceholder()
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
    );
  }
}

extension $SendMessageResponseCopyWith on SendMessageResponse {
  /// Returns a callable class that can be used as follows: `instanceOfSendMessageResponse.copyWith(...)` or like so:`instanceOfSendMessageResponse.copyWith.fieldName(...)`.
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
        );
        return val;
      },
      fieldKeyMap: const {
        'messageId': 'message_id',
        'runId': 'run_id',
        'conversationId': 'conversation_id',
      },
    );

Map<String, dynamic> _$SendMessageResponseToJson(
  SendMessageResponse instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'run_id': instance.runId,
  'conversation_id': instance.conversationId,
};
