// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_tool_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceToolRequestCWProxy {
  VoiceToolRequest botId(String botId);

  VoiceToolRequest conversationId(String conversationId);

  VoiceToolRequest callId(String callId);

  VoiceToolRequest name(String name);

  VoiceToolRequest arguments(Map<String, Object?>? arguments);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceToolRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceToolRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceToolRequest call({
    String botId,
    String conversationId,
    String callId,
    String name,
    Map<String, Object?>? arguments,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceToolRequest.copyWith(...)` or call `instanceOfVoiceToolRequest.copyWith.fieldName(value)` for a single field.
class _$VoiceToolRequestCWProxyImpl implements _$VoiceToolRequestCWProxy {
  const _$VoiceToolRequestCWProxyImpl(this._value);

  final VoiceToolRequest _value;

  @override
  VoiceToolRequest botId(String botId) => call(botId: botId);

  @override
  VoiceToolRequest conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  VoiceToolRequest callId(String callId) => call(callId: callId);

  @override
  VoiceToolRequest name(String name) => call(name: name);

  @override
  VoiceToolRequest arguments(Map<String, Object?>? arguments) =>
      call(arguments: arguments);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceToolRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceToolRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceToolRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? callId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? arguments = const $CopyWithPlaceholder(),
  }) {
    return VoiceToolRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      callId: callId == const $CopyWithPlaceholder() || callId == null
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      arguments: arguments == const $CopyWithPlaceholder()
          ? _value.arguments
          // ignore: cast_nullable_to_non_nullable
          : arguments as Map<String, Object?>?,
    );
  }
}

extension $VoiceToolRequestCopyWith on VoiceToolRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceToolRequest.copyWith(...)` or `instanceOfVoiceToolRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceToolRequestCWProxy get copyWith => _$VoiceToolRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceToolRequest _$VoiceToolRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VoiceToolRequest',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['bot_id', 'conversation_id', 'call_id', 'name'],
        );
        final val = VoiceToolRequest(
          botId: $checkedConvert('bot_id', (v) => v as String),
          conversationId: $checkedConvert(
            'conversation_id',
            (v) => v as String,
          ),
          callId: $checkedConvert('call_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          arguments: $checkedConvert(
            'arguments',
            (v) => v as Map<String, dynamic>?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'botId': 'bot_id',
        'conversationId': 'conversation_id',
        'callId': 'call_id',
      },
    );

Map<String, dynamic> _$VoiceToolRequestToJson(VoiceToolRequest instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'conversation_id': instance.conversationId,
      'call_id': instance.callId,
      'name': instance.name,
      'arguments': ?instance.arguments,
    };
