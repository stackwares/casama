//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_chat_reply_handoff.dart';
import 'package:casama_api/src/model/support_source.dart';
import 'package:casama_api/src/model/support_place.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_chat_reply.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportChatReply {
  /// Returns a new [SupportChatReply] instance.
  SupportChatReply({

    required  this.reply,

    required  this.sources,

     this.places,

    required  this.handoff,
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



  @JsonKey(
    
    name: r'handoff',
    required: true,
    includeIfNull: true,
  )


  final SupportChatReplyHandoff? handoff;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportChatReply &&
      other.reply == reply &&
      other.sources == sources &&
      other.places == places &&
      other.handoff == handoff;

    @override
    int get hashCode =>
        reply.hashCode +
        sources.hashCode +
        places.hashCode +
        (handoff == null ? 0 : handoff.hashCode);

  factory SupportChatReply.fromJson(Map<String, dynamic> json) => _$SupportChatReplyFromJson(json);

  Map<String, dynamic> toJson() => _$SupportChatReplyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

