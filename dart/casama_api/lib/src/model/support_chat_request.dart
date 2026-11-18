//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_message.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_chat_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportChatRequest {
  /// Returns a new [SupportChatRequest] instance.
  SupportChatRequest({

     this.orgId,

    required  this.messages,

     this.appVersion,

     this.platform,
  });

  @JsonKey(
    
    name: r'org_id',
    required: false,
    includeIfNull: false,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'messages',
    required: true,
    includeIfNull: false,
  )


  final List<SupportMessage> messages;



  @JsonKey(
    
    name: r'app_version',
    required: false,
    includeIfNull: false,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'platform',
    required: false,
    includeIfNull: false,
  )


  final String? platform;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportChatRequest &&
      other.orgId == orgId &&
      other.messages == messages &&
      other.appVersion == appVersion &&
      other.platform == platform;

    @override
    int get hashCode =>
        orgId.hashCode +
        messages.hashCode +
        appVersion.hashCode +
        platform.hashCode;

  factory SupportChatRequest.fromJson(Map<String, dynamic> json) => _$SupportChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SupportChatRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

