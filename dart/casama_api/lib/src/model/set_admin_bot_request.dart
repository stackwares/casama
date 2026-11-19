//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_admin_bot_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetAdminBotRequest {
  /// Returns a new [SetAdminBotRequest] instance.
  SetAdminBotRequest({

    required  this.enabled,

     this.botId,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetAdminBotRequest &&
      other.enabled == enabled &&
      other.botId == botId;

    @override
    int get hashCode =>
        enabled.hashCode +
        (botId == null ? 0 : botId.hashCode);

  factory SetAdminBotRequest.fromJson(Map<String, dynamic> json) => _$SetAdminBotRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetAdminBotRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

