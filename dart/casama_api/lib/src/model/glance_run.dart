//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_run.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceRun {
  /// Returns a new [GlanceRun] instance.
  GlanceRun({

    required  this.id,

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.phase,

    required  this.step,

    required  this.steps,

    required  this.startedAt,

    required  this.approvalId,

    required  this.risk,

    required  this.link,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'bot',
    required: true,
    includeIfNull: false,
  )


  final String bot;



  @JsonKey(
    
    name: r'bot_avatar',
    required: true,
    includeIfNull: false,
  )


  final String botAvatar;



  @JsonKey(
    
    name: r'phase',
    required: true,
    includeIfNull: false,
  )


  final GlanceRunPhaseEnum phase;



  @JsonKey(
    
    name: r'step',
    required: true,
    includeIfNull: false,
  )


  final String step;



          // minimum: 0
  @JsonKey(
    
    name: r'steps',
    required: true,
    includeIfNull: false,
  )


  final int steps;



  @JsonKey(
    
    name: r'started_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime startedAt;



  @JsonKey(
    
    name: r'approval_id',
    required: true,
    includeIfNull: true,
  )


  final String? approvalId;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: true,
  )


  final GlanceRunRiskEnum? risk;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceRun &&
      other.id == id &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.phase == phase &&
      other.step == step &&
      other.steps == steps &&
      other.startedAt == startedAt &&
      other.approvalId == approvalId &&
      other.risk == risk &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        phase.hashCode +
        step.hashCode +
        steps.hashCode +
        startedAt.hashCode +
        (approvalId == null ? 0 : approvalId.hashCode) +
        (risk == null ? 0 : risk.hashCode) +
        link.hashCode;

  factory GlanceRun.fromJson(Map<String, dynamic> json) => _$GlanceRunFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceRunToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GlanceRunPhaseEnum {
@JsonValue(r'working')
working(r'working'),
@JsonValue(r'needs_ok')
needsOk(r'needs_ok'),
@JsonValue(r'take_over')
takeOver(r'take_over');

const GlanceRunPhaseEnum(this.value);

final String value;

@override
String toString() => value;
}



enum GlanceRunRiskEnum {
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high');

const GlanceRunRiskEnum(this.value);

final String value;

@override
String toString() => value;
}


