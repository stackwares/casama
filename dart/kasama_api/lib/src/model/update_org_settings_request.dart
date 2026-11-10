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

     this.requireMfa,
  });

          // minimum: 7
          // maximum: 3650
  @JsonKey(
    
    name: r'run_event_retention_days',
    required: false,
    includeIfNull: false,
  )


  final int? runEventRetentionDays;



      /// Owners and admins must use two-step sign-in (turning it on needs an aal2 session)
  @JsonKey(
    
    name: r'require_mfa',
    required: false,
    includeIfNull: false,
  )


  final bool? requireMfa;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateOrgSettingsRequest &&
      other.runEventRetentionDays == runEventRetentionDays &&
      other.requireMfa == requireMfa;

    @override
    int get hashCode =>
        runEventRetentionDays.hashCode +
        requireMfa.hashCode;

  factory UpdateOrgSettingsRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrgSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOrgSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

