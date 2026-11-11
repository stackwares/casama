// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_transcript_request_usage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceTranscriptRequestUsageCWProxy {
  VoiceTranscriptRequestUsage inputAudioTokens(int inputAudioTokens);

  VoiceTranscriptRequestUsage inputTextTokens(int inputTextTokens);

  VoiceTranscriptRequestUsage outputAudioTokens(int outputAudioTokens);

  VoiceTranscriptRequestUsage outputTextTokens(int outputTextTokens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTranscriptRequestUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTranscriptRequestUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceTranscriptRequestUsage call({
    int inputAudioTokens,
    int inputTextTokens,
    int outputAudioTokens,
    int outputTextTokens,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceTranscriptRequestUsage.copyWith(...)` or call `instanceOfVoiceTranscriptRequestUsage.copyWith.fieldName(value)` for a single field.
class _$VoiceTranscriptRequestUsageCWProxyImpl
    implements _$VoiceTranscriptRequestUsageCWProxy {
  const _$VoiceTranscriptRequestUsageCWProxyImpl(this._value);

  final VoiceTranscriptRequestUsage _value;

  @override
  VoiceTranscriptRequestUsage inputAudioTokens(int inputAudioTokens) =>
      call(inputAudioTokens: inputAudioTokens);

  @override
  VoiceTranscriptRequestUsage inputTextTokens(int inputTextTokens) =>
      call(inputTextTokens: inputTextTokens);

  @override
  VoiceTranscriptRequestUsage outputAudioTokens(int outputAudioTokens) =>
      call(outputAudioTokens: outputAudioTokens);

  @override
  VoiceTranscriptRequestUsage outputTextTokens(int outputTextTokens) =>
      call(outputTextTokens: outputTextTokens);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceTranscriptRequestUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceTranscriptRequestUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceTranscriptRequestUsage call({
    Object? inputAudioTokens = const $CopyWithPlaceholder(),
    Object? inputTextTokens = const $CopyWithPlaceholder(),
    Object? outputAudioTokens = const $CopyWithPlaceholder(),
    Object? outputTextTokens = const $CopyWithPlaceholder(),
  }) {
    return VoiceTranscriptRequestUsage(
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

extension $VoiceTranscriptRequestUsageCopyWith on VoiceTranscriptRequestUsage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceTranscriptRequestUsage.copyWith(...)` or `instanceOfVoiceTranscriptRequestUsage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceTranscriptRequestUsageCWProxy get copyWith =>
      _$VoiceTranscriptRequestUsageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceTranscriptRequestUsage _$VoiceTranscriptRequestUsageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'VoiceTranscriptRequestUsage',
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
    final val = VoiceTranscriptRequestUsage(
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

Map<String, dynamic> _$VoiceTranscriptRequestUsageToJson(
  VoiceTranscriptRequestUsage instance,
) => <String, dynamic>{
  'input_audio_tokens': instance.inputAudioTokens,
  'input_text_tokens': instance.inputTextTokens,
  'output_audio_tokens': instance.outputAudioTokens,
  'output_text_tokens': instance.outputTextTokens,
};
