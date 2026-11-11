//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_default_invite_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateDefaultInviteRequest {
  /// Returns a new [UpdateDefaultInviteRequest] instance.
  UpdateDefaultInviteRequest({

     this.requiresApproval,

     this.reset,
  });

  @JsonKey(
    
    name: r'requires_approval',
    required: false,
    includeIfNull: false,
  )


  final bool? requiresApproval;



  @JsonKey(
    
    name: r'reset',
    required: false,
    includeIfNull: false,
  )


  final bool? reset;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateDefaultInviteRequest &&
      other.requiresApproval == requiresApproval &&
      other.reset == reset;

    @override
    int get hashCode =>
        requiresApproval.hashCode +
        reset.hashCode;

  factory UpdateDefaultInviteRequest.fromJson(Map<String, dynamic> json) => _$UpdateDefaultInviteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateDefaultInviteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

