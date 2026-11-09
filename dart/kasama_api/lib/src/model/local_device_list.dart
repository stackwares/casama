//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/local_device.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_device_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalDeviceList {
  /// Returns a new [LocalDeviceList] instance.
  LocalDeviceList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<LocalDevice> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalDeviceList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory LocalDeviceList.fromJson(Map<String, dynamic> json) => _$LocalDeviceListFromJson(json);

  Map<String, dynamic> toJson() => _$LocalDeviceListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

