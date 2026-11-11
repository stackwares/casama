//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'switch_branch_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SwitchBranchResponse {
  /// Returns a new [SwitchBranchResponse] instance.
  SwitchBranchResponse({

    required  this.headMessageId,
  });

  @JsonKey(
    
    name: r'head_message_id',
    required: true,
    includeIfNull: false,
  )


  final String headMessageId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SwitchBranchResponse &&
      other.headMessageId == headMessageId;

    @override
    int get hashCode =>
        headMessageId.hashCode;

  factory SwitchBranchResponse.fromJson(Map<String, dynamic> json) => _$SwitchBranchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SwitchBranchResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

