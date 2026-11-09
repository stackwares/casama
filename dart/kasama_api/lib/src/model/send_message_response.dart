//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_message_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendMessageResponse {
  /// Returns a new [SendMessageResponse] instance.
  SendMessageResponse({

    required  this.messageId,

    required  this.runId,

    required  this.conversationId,
  });

  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SendMessageResponse &&
      other.messageId == messageId &&
      other.runId == runId &&
      other.conversationId == conversationId;

    @override
    int get hashCode =>
        messageId.hashCode +
        runId.hashCode +
        conversationId.hashCode;

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) => _$SendMessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

