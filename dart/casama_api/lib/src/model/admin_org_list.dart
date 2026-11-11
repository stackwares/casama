//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_org.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_org_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminOrgList {
  /// Returns a new [AdminOrgList] instance.
  AdminOrgList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminOrg> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminOrgList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminOrgList.fromJson(Map<String, dynamic> json) => _$AdminOrgListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminOrgListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

