//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_bot.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceBot {
  /// Returns a new [GlanceBot] instance.
  GlanceBot({

    required  this.id,

    required  this.name,

    required  this.avatar,

    required  this.status,

    required  this.step,

    required  this.lastText,

    required  this.lastAt,

    required  this.busyAt,

    required  this.link,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'avatar',
    required: true,
    includeIfNull: false,
  )


  final String avatar;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GlanceBotStatusEnum status;



  @JsonKey(
    
    name: r'step',
    required: true,
    includeIfNull: true,
  )


  final String? step;



  @JsonKey(
    
    name: r'last_text',
    required: true,
    includeIfNull: true,
  )


  final String? lastText;



  @JsonKey(
    
    name: r'last_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastAt;



  @JsonKey(
    
    name: r'busy_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? busyAt;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceBot &&
      other.id == id &&
      other.name == name &&
      other.avatar == avatar &&
      other.status == status &&
      other.step == step &&
      other.lastText == lastText &&
      other.lastAt == lastAt &&
      other.busyAt == busyAt &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        avatar.hashCode +
        status.hashCode +
        (step == null ? 0 : step.hashCode) +
        (lastText == null ? 0 : lastText.hashCode) +
        (lastAt == null ? 0 : lastAt.hashCode) +
        (busyAt == null ? 0 : busyAt.hashCode) +
        link.hashCode;

  factory GlanceBot.fromJson(Map<String, dynamic> json) => _$GlanceBotFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceBotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GlanceBotStatusEnum {
@JsonValue(r'idle')
idle(r'idle'),
@JsonValue(r'working')
working(r'working'),
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'disabled')
disabled(r'disabled');

const GlanceBotStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


