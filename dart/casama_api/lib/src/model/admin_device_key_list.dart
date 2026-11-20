//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_device_key.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_device_key_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDeviceKeyList {
  /// Returns a new [AdminDeviceKeyList] instance.
  AdminDeviceKeyList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AdminDeviceKey> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDeviceKeyList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory AdminDeviceKeyList.fromJson(Map<String, dynamic> json) => _$AdminDeviceKeyListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDeviceKeyListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

