//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_org_settings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateOrgSettingsRequest {
  /// Returns a new [UpdateOrgSettingsRequest] instance.
  UpdateOrgSettingsRequest({

     this.runEventRetentionDays,
  });

          // minimum: 7
          // maximum: 3650
  @JsonKey(
    
    name: r'run_event_retention_days',
    required: false,
    includeIfNull: false,
  )


  final int? runEventRetentionDays;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateOrgSettingsRequest &&
      other.runEventRetentionDays == runEventRetentionDays;

    @override
    int get hashCode =>
        runEventRetentionDays.hashCode;

  factory UpdateOrgSettingsRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrgSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOrgSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

