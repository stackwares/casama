//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_surface.dart';
import 'package:casama_api/src/model/watch_audio.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_ask.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchAsk {
  /// Returns a new [WatchAsk] instance.
  WatchAsk({

    required  this.botId,

     this.conversationId,

     this.text,

     this.audio,

     this.language,

     this.askedAt,

     this.surface,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'conversation_id',
    required: false,
    includeIfNull: false,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;



  @JsonKey(
    
    name: r'audio',
    required: false,
    includeIfNull: false,
  )


  final WatchAudio? audio;



  @JsonKey(
    
    name: r'language',
    required: false,
    includeIfNull: false,
  )


  final String? language;



  @JsonKey(
    
    name: r'asked_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? askedAt;



  @JsonKey(
    
    name: r'surface',
    required: false,
    includeIfNull: false,
  )


  final WatchSurface? surface;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchAsk &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.text == text &&
      other.audio == audio &&
      other.language == language &&
      other.askedAt == askedAt &&
      other.surface == surface;

    @override
    int get hashCode =>
        botId.hashCode +
        conversationId.hashCode +
        text.hashCode +
        audio.hashCode +
        language.hashCode +
        askedAt.hashCode +
        surface.hashCode;

  factory WatchAsk.fromJson(Map<String, dynamic> json) => _$WatchAskFromJson(json);

  Map<String, dynamic> toJson() => _$WatchAskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

