//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_service.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_service_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminServiceList {
  /// Returns a new [AdminServiceList] instance.
  AdminServiceList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminService> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminServiceList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminServiceList.fromJson(Map<String, dynamic> json) => _$AdminServiceListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminServiceListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

