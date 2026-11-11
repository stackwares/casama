//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_transcript_request_usage.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceTranscriptRequestUsage {
  /// Returns a new [VoiceTranscriptRequestUsage] instance.
  VoiceTranscriptRequestUsage({

    required  this.inputAudioTokens,

    required  this.inputTextTokens,

    required  this.outputAudioTokens,

    required  this.outputTextTokens,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'input_audio_tokens',
    required: true,
    includeIfNull: false,
  )


  final int inputAudioTokens;



          // minimum: 0
  @JsonKey(
    
    name: r'input_text_tokens',
    required: true,
    includeIfNull: false,
  )


  final int inputTextTokens;



          // minimum: 0
  @JsonKey(
    
    name: r'output_audio_tokens',
    required: true,
    includeIfNull: false,
  )


  final int outputAudioTokens;



          // minimum: 0
  @JsonKey(
    
    name: r'output_text_tokens',
    required: true,
    includeIfNull: false,
  )


  final int outputTextTokens;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTranscriptRequestUsage &&
      other.inputAudioTokens == inputAudioTokens &&
      other.inputTextTokens == inputTextTokens &&
      other.outputAudioTokens == outputAudioTokens &&
      other.outputTextTokens == outputTextTokens;

    @override
    int get hashCode =>
        inputAudioTokens.hashCode +
        inputTextTokens.hashCode +
        outputAudioTokens.hashCode +
        outputTextTokens.hashCode;

  factory VoiceTranscriptRequestUsage.fromJson(Map<String, dynamic> json) => _$VoiceTranscriptRequestUsageFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTranscriptRequestUsageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

