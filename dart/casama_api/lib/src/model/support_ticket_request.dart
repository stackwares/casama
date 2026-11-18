//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_message.dart';
import 'package:casama_api/src/model/support_topic.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_ticket_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportTicketRequest {
  /// Returns a new [SupportTicketRequest] instance.
  SupportTicketRequest({

     this.orgId,

    required  this.topic,

    required  this.message,

     this.transcript,

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
    
    name: r'topic',
    required: true,
    includeIfNull: false,
  )


  final SupportTopic topic;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;



  @JsonKey(
    
    name: r'transcript',
    required: false,
    includeIfNull: false,
  )


  final List<SupportMessage>? transcript;



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
    bool operator ==(Object other) => identical(this, other) || other is SupportTicketRequest &&
      other.orgId == orgId &&
      other.topic == topic &&
      other.message == message &&
      other.transcript == transcript &&
      other.appVersion == appVersion &&
      other.platform == platform;

    @override
    int get hashCode =>
        orgId.hashCode +
        topic.hashCode +
        message.hashCode +
        transcript.hashCode +
        appVersion.hashCode +
        platform.hashCode;

  factory SupportTicketRequest.fromJson(Map<String, dynamic> json) => _$SupportTicketRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

