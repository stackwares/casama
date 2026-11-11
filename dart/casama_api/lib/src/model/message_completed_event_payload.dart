//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_completed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageCompletedEventPayload {
  /// Returns a new [MessageCompletedEventPayload] instance.
  MessageCompletedEventPayload({

    required  this.messageId,

    required  this.content,
  });

  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final List<Map<String, Object?>> content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageCompletedEventPayload &&
      other.messageId == messageId &&
      other.content == content;

    @override
    int get hashCode =>
        messageId.hashCode +
        content.hashCode;

  factory MessageCompletedEventPayload.fromJson(Map<String, dynamic> json) => _$MessageCompletedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$MessageCompletedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

