//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_delta_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageDeltaEventPayload {
  /// Returns a new [MessageDeltaEventPayload] instance.
  MessageDeltaEventPayload({

    required  this.messageId,

    required  this.text,
  });

  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageDeltaEventPayload &&
      other.messageId == messageId &&
      other.text == text;

    @override
    int get hashCode =>
        messageId.hashCode +
        text.hashCode;

  factory MessageDeltaEventPayload.fromJson(Map<String, dynamic> json) => _$MessageDeltaEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$MessageDeltaEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

