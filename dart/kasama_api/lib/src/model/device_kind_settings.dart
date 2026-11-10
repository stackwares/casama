//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_kind_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceKindSettings {
  /// Returns a new [DeviceKindSettings] instance.
  DeviceKindSettings({

     this.retentionDays,

     this.privateModel,
  });

      /// 0 keeps nothing (live only); the default is 365 for daily summaries, 90 for places and notifications
          // minimum: 0
          // maximum: 365
  @JsonKey(
    
    name: r'retention_days',
    required: false,
    includeIfNull: false,
  )


  final int? retentionDays;



      /// Only bots on a private (local) model may read this kind
  @JsonKey(
    
    name: r'private_model',
    required: false,
    includeIfNull: false,
  )


  final bool? privateModel;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceKindSettings &&
      other.retentionDays == retentionDays &&
      other.privateModel == privateModel;

    @override
    int get hashCode =>
        retentionDays.hashCode +
        privateModel.hashCode;

  factory DeviceKindSettings.fromJson(Map<String, dynamic> json) => _$DeviceKindSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceKindSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

