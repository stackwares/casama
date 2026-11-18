//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_web_chat_request_messages_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_chat_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebChatRequest {
  /// Returns a new [SupportWebChatRequest] instance.
  SupportWebChatRequest({

    required  this.session,

    required  this.messages,

     this.page,
  });

  @JsonKey(
    
    name: r'session',
    required: true,
    includeIfNull: false,
  )


  final String session;



  @JsonKey(
    
    name: r'messages',
    required: true,
    includeIfNull: false,
  )


  final List<SupportWebChatRequestMessagesInner> messages;



  @JsonKey(
    
    name: r'page',
    required: false,
    includeIfNull: false,
  )


  final String? page;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebChatRequest &&
      other.session == session &&
      other.messages == messages &&
      other.page == page;

    @override
    int get hashCode =>
        session.hashCode +
        messages.hashCode +
        page.hashCode;

  factory SupportWebChatRequest.fromJson(Map<String, dynamic> json) => _$SupportWebChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebChatRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

