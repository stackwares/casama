//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'move_mail_address_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MoveMailAddressRequest {
  /// Returns a new [MoveMailAddressRequest] instance.
  MoveMailAddressRequest({

    required  this.toBotId,
  });

  @JsonKey(
    
    name: r'to_bot_id',
    required: true,
    includeIfNull: false,
  )


  final String toBotId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MoveMailAddressRequest &&
      other.toBotId == toBotId;

    @override
    int get hashCode =>
        toBotId.hashCode;

  factory MoveMailAddressRequest.fromJson(Map<String, dynamic> json) => _$MoveMailAddressRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MoveMailAddressRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

