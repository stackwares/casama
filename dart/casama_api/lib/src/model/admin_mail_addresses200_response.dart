//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_mail_address.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_mail_addresses200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMailAddresses200Response {
  /// Returns a new [AdminMailAddresses200Response] instance.
  AdminMailAddresses200Response({

    required  this.items,

     this.sentToday,

     this.sendCeiling,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMailAddress> items;



  @JsonKey(
    
    name: r'sent_today',
    required: false,
    includeIfNull: false,
  )


  final int? sentToday;



  @JsonKey(
    
    name: r'send_ceiling',
    required: false,
    includeIfNull: false,
  )


  final int? sendCeiling;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMailAddresses200Response &&
      other.items == items &&
      other.sentToday == sentToday &&
      other.sendCeiling == sendCeiling;

    @override
    int get hashCode =>
        items.hashCode +
        sentToday.hashCode +
        (sendCeiling == null ? 0 : sendCeiling.hashCode);

  factory AdminMailAddresses200Response.fromJson(Map<String, dynamic> json) => _$AdminMailAddresses200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMailAddresses200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

