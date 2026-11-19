//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_approval.dart';
import 'package:casama_api/src/model/watch_message.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_run.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchRun {
  /// Returns a new [WatchRun] instance.
  WatchRun({

    required  this.id,

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.conversationId,

    required  this.phase,

    required  this.step,

    required  this.steps,

    required  this.startedAt,

    required  this.endedAt,

    required  this.approval,

    required  this.reply,

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
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'phase',
    required: true,
    includeIfNull: false,
  )


  final WatchRunPhaseEnum phase;



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
    
    name: r'ended_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? endedAt;



  @JsonKey(
    
    name: r'approval',
    required: true,
    includeIfNull: true,
  )


  final WatchApproval? approval;



  @JsonKey(
    
    name: r'reply',
    required: true,
    includeIfNull: true,
  )


  final WatchMessage? reply;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchRun &&
      other.id == id &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.conversationId == conversationId &&
      other.phase == phase &&
      other.step == step &&
      other.steps == steps &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.approval == approval &&
      other.reply == reply &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        phase.hashCode +
        step.hashCode +
        steps.hashCode +
        startedAt.hashCode +
        (endedAt == null ? 0 : endedAt.hashCode) +
        (approval == null ? 0 : approval.hashCode) +
        (reply == null ? 0 : reply.hashCode) +
        link.hashCode;

  factory WatchRun.fromJson(Map<String, dynamic> json) => _$WatchRunFromJson(json);

  Map<String, dynamic> toJson() => _$WatchRunToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchRunPhaseEnum {
@JsonValue(r'working')
working(r'working'),
@JsonValue(r'needs_ok')
needsOk(r'needs_ok'),
@JsonValue(r'take_over')
takeOver(r'take_over'),
@JsonValue(r'finished')
finished(r'finished'),
@JsonValue(r'problem')
problem(r'problem'),
@JsonValue(r'stopped')
stopped(r'stopped');

const WatchRunPhaseEnum(this.value);

final String value;

@override
String toString() => value;
}


