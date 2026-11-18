//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cloud_models.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CloudModels {
  /// Returns a new [CloudModels] instance.
  CloudModels({

    required  this.chat,

    required  this.background,

    required  this.image,

    required  this.imageResolution,

    required  this.live,

    required  this.tts,

    required  this.stt,

    required  this.embedding,

    required  this.video,
  });

      /// OpenRouter model for chat on Casama's key.
  @JsonKey(
    
    name: r'chat',
    required: true,
    includeIfNull: false,
  )


  final String chat;



      /// OpenRouter model for summaries, memory and briefs.
  @JsonKey(
    
    name: r'background',
    required: true,
    includeIfNull: false,
  )


  final String background;



      /// OpenRouter image model.
  @JsonKey(
    
    name: r'image',
    required: true,
    includeIfNull: false,
  )


  final String image;



  @JsonKey(
    
    name: r'image_resolution',
    required: true,
    includeIfNull: false,
  )


  final CloudModelsImageResolutionEnum imageResolution;



      /// Gemini Live model for calls.
  @JsonKey(
    
    name: r'live',
    required: true,
    includeIfNull: false,
  )


  final String live;



      /// OpenRouter text-to-speech model for read aloud (google/gemini-3.8-flash-lite-tts).
  @JsonKey(
    
    name: r'tts',
    required: true,
    includeIfNull: false,
  )


  final String tts;



      /// OpenRouter transcription model for dictation (openai/whisper-large-v3-turbo).
  @JsonKey(
    
    name: r'stt',
    required: true,
    includeIfNull: false,
  )


  final String stt;



      /// OpenAI embedding model.
  @JsonKey(
    
    name: r'embedding',
    required: true,
    includeIfNull: false,
  )


  final String embedding;



      /// OpenRouter video model (google/gemini-omni-1.2-flash).
  @JsonKey(
    
    name: r'video',
    required: true,
    includeIfNull: false,
  )


  final String video;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CloudModels &&
      other.chat == chat &&
      other.background == background &&
      other.image == image &&
      other.imageResolution == imageResolution &&
      other.live == live &&
      other.tts == tts &&
      other.stt == stt &&
      other.embedding == embedding &&
      other.video == video;

    @override
    int get hashCode =>
        chat.hashCode +
        background.hashCode +
        image.hashCode +
        imageResolution.hashCode +
        live.hashCode +
        tts.hashCode +
        stt.hashCode +
        embedding.hashCode +
        video.hashCode;

  factory CloudModels.fromJson(Map<String, dynamic> json) => _$CloudModelsFromJson(json);

  Map<String, dynamic> toJson() => _$CloudModelsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CloudModelsImageResolutionEnum {
@JsonValue(r'1K')
n1k(r'1K'),
@JsonValue(r'2K')
n2k(r'2K'),
@JsonValue(r'4K')
n4k(r'4K');

const CloudModelsImageResolutionEnum(this.value);

final String value;

@override
String toString() => value;
}


