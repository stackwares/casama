//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_admin_workspace_limit_reset_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionAdminWorkspaceLimitResetRequest {
  /// Returns a new [ActionAdminWorkspaceLimitResetRequest] instance.
  ActionAdminWorkspaceLimitResetRequest({

    required  this.action,
  });

  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final ActionAdminWorkspaceLimitResetRequestActionEnum action;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActionAdminWorkspaceLimitResetRequest &&
      other.action == action;

    @override
    int get hashCode =>
        action.hashCode;

  factory ActionAdminWorkspaceLimitResetRequest.fromJson(Map<String, dynamic> json) => _$ActionAdminWorkspaceLimitResetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ActionAdminWorkspaceLimitResetRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ActionAdminWorkspaceLimitResetRequestActionEnum {
@JsonValue(r'revoke')
revoke(r'revoke'),
@JsonValue(r'undo')
undo(r'undo');

const ActionAdminWorkspaceLimitResetRequestActionEnum(this.value);

final String value;

@override
String toString() => value;
}


