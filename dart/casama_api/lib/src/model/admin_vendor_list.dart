//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_vendor.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_vendor_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminVendorList {
  /// Returns a new [AdminVendorList] instance.
  AdminVendorList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminVendor> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminVendorList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminVendorList.fromJson(Map<String, dynamic> json) => _$AdminVendorListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminVendorListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

