//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_bot_setting.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminBotSetting {
  /// Returns a new [AdminBotSetting] instance.
  AdminBotSetting({

    required  this.enabled,

    required  this.botId,

    required  this.available,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



      /// The bot. It must be in a workspace whose every member is an instance owner (INSTANCE_ADMIN_EMAILS).
  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



      /// False when INSTANCE_ADMIN_EMAILS isn't set: the admin bot can't be used.
  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminBotSetting &&
      other.enabled == enabled &&
      other.botId == botId &&
      other.available == available;

    @override
    int get hashCode =>
        enabled.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        available.hashCode;

  factory AdminBotSetting.fromJson(Map<String, dynamic> json) => _$AdminBotSettingFromJson(json);

  Map<String, dynamic> toJson() => _$AdminBotSettingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

