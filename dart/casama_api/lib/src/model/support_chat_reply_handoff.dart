//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_topic.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_chat_reply_handoff.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportChatReplyHandoff {
  /// Returns a new [SupportChatReplyHandoff] instance.
  SupportChatReplyHandoff({

    required  this.topic,

    required  this.summary,
  });

  @JsonKey(
    
    name: r'topic',
    required: true,
    includeIfNull: false,
  )


  final SupportTopic topic;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportChatReplyHandoff &&
      other.topic == topic &&
      other.summary == summary;

    @override
    int get hashCode =>
        topic.hashCode +
        summary.hashCode;

  factory SupportChatReplyHandoff.fromJson(Map<String, dynamic> json) => _$SupportChatReplyHandoffFromJson(json);

  Map<String, dynamic> toJson() => _$SupportChatReplyHandoffToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

