// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_transcript_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceTranscriptRequestCWProxy {
  VoiceTranscriptRequest conversationId(String conversationId);

  VoiceTranscriptRequest turns(List<VoiceTranscriptRequestTurnsInner> turns);

  VoiceTranscriptRequest seconds(int seconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTranscriptRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTranscriptRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceTranscriptRequest call({
    String conversationId,
    List<VoiceTranscriptRequestTurnsInner> turns,
    int seconds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceTranscriptRequest.copyWith(...)` or call `instanceOfVoiceTranscriptRequest.copyWith.fieldName(value)` for a single field.
class _$VoiceTranscriptRequestCWProxyImpl
    implements _$VoiceTranscriptRequestCWProxy {
  const _$VoiceTranscriptRequestCWProxyImpl(this._value);

  final VoiceTranscriptRequest _value;

  @override
  VoiceTranscriptRequest conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  VoiceTranscriptRequest turns(List<VoiceTranscriptRequestTurnsInner> turns) =>
      call(turns: turns);

  @override
  VoiceTranscriptRequest seconds(int seconds) => call(seconds: seconds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTranscriptRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTranscriptRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceTranscriptRequest call({
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? turns = const $CopyWithPlaceholder(),
    Object? seconds = const $CopyWithPlaceholder(),
  }) {
    return VoiceTranscriptRequest(
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      turns: turns == const $CopyWithPlaceholder() || turns == null
          ? _value.turns
          // ignore: cast_nullable_to_non_nullable
          : turns as List<VoiceTranscriptRequestTurnsInner>,
      seconds: seconds == const $CopyWithPlaceholder() || seconds == null
          ? _value.seconds
          // ignore: cast_nullable_to_non_nullable
          : seconds as int,
    );
  }
}

extension $VoiceTranscriptRequestCopyWith on VoiceTranscriptRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceTranscriptRequest.copyWith(...)` or `instanceOfVoiceTranscriptRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceTranscriptRequestCWProxy get copyWith =>
      _$VoiceTranscriptRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceTranscriptRequest _$VoiceTranscriptRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VoiceTranscriptRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['conversation_id', 'turns', 'seconds']);
  final val = VoiceTranscriptRequest(
    conversationId: $checkedConvert('conversation_id', (v) => v as String),
    turns: $checkedConvert(
      'turns',
      (v) => (v as List<dynamic>)
          .map(
            (e) => VoiceTranscriptRequestTurnsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    seconds: $checkedConvert('seconds', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'conversationId': 'conversation_id'});

Map<String, dynamic> _$VoiceTranscriptRequestToJson(
  VoiceTranscriptRequest instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'turns': instance.turns.map((e) => e.toJson()).toList(),
  'seconds': instance.seconds,
};
