//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_admin_limit_reset_campaign_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionAdminLimitResetCampaignRequest {
  /// Returns a new [ActionAdminLimitResetCampaignRequest] instance.
  ActionAdminLimitResetCampaignRequest({

    required  this.action,
  });

  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final ActionAdminLimitResetCampaignRequestActionEnum action;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActionAdminLimitResetCampaignRequest &&
      other.action == action;

    @override
    int get hashCode =>
        action.hashCode;

  factory ActionAdminLimitResetCampaignRequest.fromJson(Map<String, dynamic> json) => _$ActionAdminLimitResetCampaignRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ActionAdminLimitResetCampaignRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ActionAdminLimitResetCampaignRequestActionEnum {
@JsonValue(r'schedule')
schedule(r'schedule'),
@JsonValue(r'pause')
pause(r'pause'),
@JsonValue(r'resume')
resume(r'resume'),
@JsonValue(r'cancel')
cancel(r'cancel'),
@JsonValue(r'delete')
delete(r'delete');

const ActionAdminLimitResetCampaignRequestActionEnum(this.value);

final String value;

@override
String toString() => value;
}


