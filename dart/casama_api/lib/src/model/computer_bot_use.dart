//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_bot_use.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerBotUse {
  /// Returns a new [ComputerBotUse] instance.
  ComputerBotUse({

    required  this.botId,

    required  this.name,

    required  this.lastActiveAt,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'last_active_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastActiveAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerBotUse &&
      other.botId == botId &&
      other.name == name &&
      other.lastActiveAt == lastActiveAt;

    @override
    int get hashCode =>
        botId.hashCode +
        name.hashCode +
        (lastActiveAt == null ? 0 : lastActiveAt.hashCode);

  factory ComputerBotUse.fromJson(Map<String, dynamic> json) => _$ComputerBotUseFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerBotUseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

