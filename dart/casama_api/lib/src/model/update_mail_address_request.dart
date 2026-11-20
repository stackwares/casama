//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_mail_address_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateMailAddressRequest {
  /// Returns a new [UpdateMailAddressRequest] instance.
  UpdateMailAddressRequest({

     this.status,

     this.notifyNewSenders,
  });

  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  )


  final UpdateMailAddressRequestStatusEnum? status;



  @JsonKey(
    
    name: r'notify_new_senders',
    required: false,
    includeIfNull: false,
  )


  final bool? notifyNewSenders;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateMailAddressRequest &&
      other.status == status &&
      other.notifyNewSenders == notifyNewSenders;

    @override
    int get hashCode =>
        status.hashCode +
        notifyNewSenders.hashCode;

  factory UpdateMailAddressRequest.fromJson(Map<String, dynamic> json) => _$UpdateMailAddressRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMailAddressRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UpdateMailAddressRequestStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'paused')
paused(r'paused');

const UpdateMailAddressRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


