//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_mail_address.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMailAddress {
  /// Returns a new [AdminMailAddress] instance.
  AdminMailAddress({

    required  this.id,

    required  this.address,

    required  this.orgId,

    required  this.orgName,

    required  this.botId,

    required  this.botName,

    required  this.status,

    required  this.autoPaused,

    required  this.sent30d,

    required  this.bounced30d,

    required  this.complained30d,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'address',
    required: true,
    includeIfNull: false,
  )


  final String address;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: true,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: false,
  )


  final String orgName;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'bot_name',
    required: true,
    includeIfNull: false,
  )


  final String botName;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final AdminMailAddressStatusEnum status;



  @JsonKey(
    
    name: r'auto_paused',
    required: true,
    includeIfNull: false,
  )


  final bool autoPaused;



  @JsonKey(
    
    name: r'sent_30d',
    required: true,
    includeIfNull: false,
  )


  final int sent30d;



  @JsonKey(
    
    name: r'bounced_30d',
    required: true,
    includeIfNull: false,
  )


  final int bounced30d;



  @JsonKey(
    
    name: r'complained_30d',
    required: true,
    includeIfNull: false,
  )


  final int complained30d;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMailAddress &&
      other.id == id &&
      other.address == address &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.botId == botId &&
      other.botName == botName &&
      other.status == status &&
      other.autoPaused == autoPaused &&
      other.sent30d == sent30d &&
      other.bounced30d == bounced30d &&
      other.complained30d == complained30d &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        address.hashCode +
        (orgId == null ? 0 : orgId.hashCode) +
        orgName.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        botName.hashCode +
        status.hashCode +
        autoPaused.hashCode +
        sent30d.hashCode +
        bounced30d.hashCode +
        complained30d.hashCode +
        createdAt.hashCode;

  factory AdminMailAddress.fromJson(Map<String, dynamic> json) => _$AdminMailAddressFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMailAddressToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AdminMailAddressStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'paused')
paused(r'paused'),
@JsonValue(r'retired')
retired(r'retired');

const AdminMailAddressStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


