//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_admin_limit_reset_campaign200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionAdminLimitResetCampaign200Response {
  /// Returns a new [ActionAdminLimitResetCampaign200Response] instance.
  ActionAdminLimitResetCampaign200Response({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActionAdminLimitResetCampaign200Response &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory ActionAdminLimitResetCampaign200Response.fromJson(Map<String, dynamic> json) => _$ActionAdminLimitResetCampaign200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActionAdminLimitResetCampaign200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

