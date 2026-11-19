//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_source.dart';
import 'package:casama_api/src/model/support_place.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_chat_reply.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebChatReply {
  /// Returns a new [SupportWebChatReply] instance.
  SupportWebChatReply({

    required  this.reply,

    required  this.sources,

     this.places,
  });

  @JsonKey(
    
    name: r'reply',
    required: true,
    includeIfNull: false,
  )


  final String reply;



  @JsonKey(
    
    name: r'sources',
    required: true,
    includeIfNull: false,
  )


  final List<SupportSource> sources;



  @JsonKey(
    
    name: r'places',
    required: false,
    includeIfNull: false,
  )


  final List<SupportPlace>? places;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebChatReply &&
      other.reply == reply &&
      other.sources == sources &&
      other.places == places;

    @override
    int get hashCode =>
        reply.hashCode +
        sources.hashCode +
        places.hashCode;

  factory SupportWebChatReply.fromJson(Map<String, dynamic> json) => _$SupportWebChatReplyFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebChatReplyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

