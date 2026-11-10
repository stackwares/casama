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

     this.extras,
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



      /// Health only: sensitive extras the person turned on (off by default)
  @JsonKey(
    
    name: r'extras',
    required: false,
    includeIfNull: false,
  )


  final List<DeviceKindSettingsExtrasEnum>? extras;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceKindSettings &&
      other.retentionDays == retentionDays &&
      other.privateModel == privateModel &&
      other.extras == extras;

    @override
    int get hashCode =>
        retentionDays.hashCode +
        privateModel.hashCode +
        extras.hashCode;

  factory DeviceKindSettings.fromJson(Map<String, dynamic> json) => _$DeviceKindSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceKindSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceKindSettingsExtrasEnum {
@JsonValue(r'cycle')
cycle(r'cycle'),
@JsonValue(r'glucose')
glucose(r'glucose'),
@JsonValue(r'blood_pressure')
bloodPressure(r'blood_pressure');

const DeviceKindSettingsExtrasEnum(this.value);

final String value;

@override
String toString() => value;
}


