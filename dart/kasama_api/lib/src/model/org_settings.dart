//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'org_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrgSettings {
  /// Returns a new [OrgSettings] instance.
  OrgSettings({

    required  this.runEventRetentionDays,
  });

          // minimum: 7
          // maximum: 3650
  @JsonKey(
    
    name: r'run_event_retention_days',
    required: true,
    includeIfNull: false,
  )


  final int runEventRetentionDays;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OrgSettings &&
      other.runEventRetentionDays == runEventRetentionDays;

    @override
    int get hashCode =>
        runEventRetentionDays.hashCode;

  factory OrgSettings.fromJson(Map<String, dynamic> json) => _$OrgSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$OrgSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

