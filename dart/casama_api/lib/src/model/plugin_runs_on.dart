//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_runs_on.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginRunsOn {
  /// Returns a new [PluginRunsOn] instance.
  PluginRunsOn({

    required  this.deviceId,

    required  this.deviceName,

    required  this.ownerUserId,

    required  this.online,
  });

  @JsonKey(
    
    name: r'device_id',
    required: true,
    includeIfNull: false,
  )


  final String deviceId;



  @JsonKey(
    
    name: r'device_name',
    required: true,
    includeIfNull: false,
  )


  final String deviceName;



  @JsonKey(
    
    name: r'owner_user_id',
    required: true,
    includeIfNull: false,
  )


  final String ownerUserId;



  @JsonKey(
    
    name: r'online',
    required: true,
    includeIfNull: false,
  )


  final bool online;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginRunsOn &&
      other.deviceId == deviceId &&
      other.deviceName == deviceName &&
      other.ownerUserId == ownerUserId &&
      other.online == online;

    @override
    int get hashCode =>
        deviceId.hashCode +
        deviceName.hashCode +
        ownerUserId.hashCode +
        online.hashCode;

  factory PluginRunsOn.fromJson(Map<String, dynamic> json) => _$PluginRunsOnFromJson(json);

  Map<String, dynamic> toJson() => _$PluginRunsOnToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

