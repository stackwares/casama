//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/approval.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approval_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApprovalList {
  /// Returns a new [ApprovalList] instance.
  ApprovalList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Approval> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApprovalList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ApprovalList.fromJson(Map<String, dynamic> json) => _$ApprovalListFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

