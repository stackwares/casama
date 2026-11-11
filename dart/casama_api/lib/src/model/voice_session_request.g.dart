// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_session_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceSessionRequestCWProxy {
  VoiceSessionRequest botId(String botId);

  VoiceSessionRequest conversationId(String? conversationId);

  VoiceSessionRequest callId(String? callId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceSessionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceSessionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceSessionRequest call({
    String botId,
    String? conversationId,
    String? callId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceSessionRequest.copyWith(...)` or call `instanceOfVoiceSessionRequest.copyWith.fieldName(value)` for a single field.
class _$VoiceSessionRequestCWProxyImpl implements _$VoiceSessionRequestCWProxy {
  const _$VoiceSessionRequestCWProxyImpl(this._value);

  final VoiceSessionRequest _value;

  @override
  VoiceSessionRequest botId(String botId) => call(botId: botId);

  @override
  VoiceSessionRequest conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  VoiceSessionRequest callId(String? callId) => call(callId: callId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceSessionRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceSessionRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceSessionRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? callId = const $CopyWithPlaceholder(),
  }) {
    return VoiceSessionRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      callId: callId == const $CopyWithPlaceholder()
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String?,
    );
  }
}

extension $VoiceSessionRequestCopyWith on VoiceSessionRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceSessionRequest.copyWith(...)` or `instanceOfVoiceSessionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceSessionRequestCWProxy get copyWith =>
      _$VoiceSessionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSessionRequest _$VoiceSessionRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VoiceSessionRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['bot_id']);
        final val = VoiceSessionRequest(
          botId: $checkedConvert('bot_id', (v) => v as String),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String?,
          ),
          callId: $checkedConvert('call_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'botId': 'bot_id',
        'conversationId': 'conversation_id',
        'callId': 'call_id',
      },
    );

Map<String, dynamic> _$VoiceSessionRequestToJson(
  VoiceSessionRequest instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'conversation_id': ?instance.conversationId,
  'call_id': ?instance.callId,
};
