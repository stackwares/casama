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
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMailAddress> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMailAddresses200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminMailAddresses200Response.fromJson(Map<String, dynamic> json) => _$AdminMailAddresses200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMailAddresses200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

