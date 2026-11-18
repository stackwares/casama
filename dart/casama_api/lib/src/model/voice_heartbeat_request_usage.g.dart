// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_heartbeat_request_usage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceHeartbeatRequestUsageCWProxy {
  VoiceHeartbeatRequestUsage inputAudioTokens(int inputAudioTokens);

  VoiceHeartbeatRequestUsage inputTextTokens(int inputTextTokens);

  VoiceHeartbeatRequestUsage outputAudioTokens(int outputAudioTokens);

  VoiceHeartbeatRequestUsage outputTextTokens(int outputTextTokens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceHeartbeatRequestUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceHeartbeatRequestUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceHeartbeatRequestUsage call({
    int inputAudioTokens,
    int inputTextTokens,
    int outputAudioTokens,
    int outputTextTokens,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceHeartbeatRequestUsage.copyWith(...)` or call `instanceOfVoiceHeartbeatRequestUsage.copyWith.fieldName(value)` for a single field.
class _$VoiceHeartbeatRequestUsageCWProxyImpl
    implements _$VoiceHeartbeatRequestUsageCWProxy {
  const _$VoiceHeartbeatRequestUsageCWProxyImpl(this._value);

  final VoiceHeartbeatRequestUsage _value;

  @override
  VoiceHeartbeatRequestUsage inputAudioTokens(int inputAudioTokens) =>
      call(inputAudioTokens: inputAudioTokens);

  @override
  VoiceHeartbeatRequestUsage inputTextTokens(int inputTextTokens) =>
      call(inputTextTokens: inputTextTokens);

  @override
  VoiceHeartbeatRequestUsage outputAudioTokens(int outputAudioTokens) =>
      call(outputAudioTokens: outputAudioTokens);

  @override
  VoiceHeartbeatRequestUsage outputTextTokens(int outputTextTokens) =>
      call(outputTextTokens: outputTextTokens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceHeartbeatRequestUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceHeartbeatRequestUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceHeartbeatRequestUsage call({
    Object? inputAudioTokens = const $CopyWithPlaceholder(),
    Object? inputTextTokens = const $CopyWithPlaceholder(),
    Object? outputAudioTokens = const $CopyWithPlaceholder(),
    Object? outputTextTokens = const $CopyWithPlaceholder(),
  }) {
    return VoiceHeartbeatRequestUsage(
      inputAudioTokens:
          inputAudioTokens == const $CopyWithPlaceholder() ||
              inputAudioTokens == null
          ? _value.inputAudioTokens
          // ignore: cast_nullable_to_non_nullable
          : inputAudioTokens as int,
      inputTextTokens:
          inputTextTokens == const $CopyWithPlaceholder() ||
              inputTextTokens == null
          ? _value.inputTextTokens
          // ignore: cast_nullable_to_non_nullable
          : inputTextTokens as int,
      outputAudioTokens:
          outputAudioTokens == const $CopyWithPlaceholder() ||
              outputAudioTokens == null
          ? _value.outputAudioTokens
          // ignore: cast_nullable_to_non_nullable
          : outputAudioTokens as int,
      outputTextTokens:
          outputTextTokens == const $CopyWithPlaceholder() ||
              outputTextTokens == null
          ? _value.outputTextTokens
          // ignore: cast_nullable_to_non_nullable
          : outputTextTokens as int,
    );
  }
}

extension $VoiceHeartbeatRequestUsageCopyWith on VoiceHeartbeatRequestUsage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceHeartbeatRequestUsage.copyWith(...)` or `instanceOfVoiceHeartbeatRequestUsage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceHeartbeatRequestUsageCWProxy get copyWith =>
      _$VoiceHeartbeatRequestUsageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceHeartbeatRequestUsage _$VoiceHeartbeatRequestUsageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'VoiceHeartbeatRequestUsage',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'input_audio_tokens',
        'input_text_tokens',
        'output_audio_tokens',
        'output_text_tokens',
      ],
    );
    final val = VoiceHeartbeatRequestUsage(
      inputAudioTokens: $checkedConvert(
        'input_audio_tokens',
        (v) => (v as num).toInt(),
      ),
      inputTextTokens: $checkedConvert(
        'input_text_tokens',
        (v) => (v as num).toInt(),
      ),
      outputAudioTokens: $checkedConvert(
        'output_audio_tokens',
        (v) => (v as num).toInt(),
      ),
      outputTextTokens: $checkedConvert(
        'output_text_tokens',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'inputAudioTokens': 'input_audio_tokens',
    'inputTextTokens': 'input_text_tokens',
    'outputAudioTokens': 'output_audio_tokens',
    'outputTextTokens': 'output_text_tokens',
  },
);

Map<String, dynamic> _$VoiceHeartbeatRequestUsageToJson(
  VoiceHeartbeatRequestUsage instance,
) => <String, dynamic>{
  'input_audio_tokens': instance.inputAudioTokens,
  'input_text_tokens': instance.inputTextTokens,
  'output_audio_tokens': instance.outputAudioTokens,
  'output_text_tokens': instance.outputTextTokens,
};
