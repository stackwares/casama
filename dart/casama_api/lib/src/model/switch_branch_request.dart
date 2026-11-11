//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'switch_branch_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SwitchBranchRequest {
  /// Returns a new [SwitchBranchRequest] instance.
  SwitchBranchRequest({

    required  this.messageId,
  });

      /// A message on the branch to show
  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SwitchBranchRequest &&
      other.messageId == messageId;

    @override
    int get hashCode =>
        messageId.hashCode;

  factory SwitchBranchRequest.fromJson(Map<String, dynamic> json) => _$SwitchBranchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SwitchBranchRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

