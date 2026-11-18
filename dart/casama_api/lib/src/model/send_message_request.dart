//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/ui_action_part.dart';
import 'package:casama_api/src/model/message_attachment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_message_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendMessageRequest {
  /// Returns a new [SendMessageRequest] instance.
  SendMessageRequest({

     this.text = '',

     this.attachments,

     this.uiAction,

     this.skills,
  });

  @JsonKey(
    defaultValue: '',
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;



  @JsonKey(
    
    name: r'attachments',
    required: false,
    includeIfNull: false,
  )


  final List<MessageAttachment>? attachments;



  @JsonKey(
    
    name: r'ui_action',
    required: false,
    includeIfNull: false,
  )


  final UiActionPart? uiAction;



      /// Skills picked with / in the composer; the run loads them up front
  @JsonKey(
    
    name: r'skills',
    required: false,
    includeIfNull: false,
  )


  final List<String>? skills;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SendMessageRequest &&
      other.text == text &&
      other.attachments == attachments &&
      other.uiAction == uiAction &&
      other.skills == skills;

    @override
    int get hashCode =>
        text.hashCode +
        attachments.hashCode +
        uiAction.hashCode +
        skills.hashCode;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) => _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

