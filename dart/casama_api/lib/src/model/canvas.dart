//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/canvas_entry.dart';
import 'package:casama_api/src/model/canvas_rotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Canvas {
  /// Returns a new [Canvas] instance.
  Canvas({

    required  this.id,

    required  this.orgId,

    required  this.name,

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.status,

    required  this.hideWhenLocked,

    required  this.version,

    required  this.setAt,

    required  this.until,

    required  this.link,

    required  this.rotation,

    required  this.entries,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



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
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final CanvasStatusEnum status;



  @JsonKey(
    
    name: r'hide_when_locked',
    required: true,
    includeIfNull: false,
  )


  final bool hideWhenLocked;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'set_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime setAt;



  @JsonKey(
    
    name: r'until',
    required: true,
    includeIfNull: true,
  )


  final DateTime? until;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;



  @JsonKey(
    
    name: r'rotation',
    required: true,
    includeIfNull: true,
  )


  final CanvasRotation? rotation;



  @JsonKey(
    
    name: r'entries',
    required: true,
    includeIfNull: false,
  )


  final List<CanvasEntry> entries;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Canvas &&
      other.id == id &&
      other.orgId == orgId &&
      other.name == name &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.status == status &&
      other.hideWhenLocked == hideWhenLocked &&
      other.version == version &&
      other.setAt == setAt &&
      other.until == until &&
      other.link == link &&
      other.rotation == rotation &&
      other.entries == entries;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        name.hashCode +
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        status.hashCode +
        hideWhenLocked.hashCode +
        version.hashCode +
        setAt.hashCode +
        (until == null ? 0 : until.hashCode) +
        link.hashCode +
        (rotation == null ? 0 : rotation.hashCode) +
        entries.hashCode;

  factory Canvas.fromJson(Map<String, dynamic> json) => _$CanvasFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasStatusEnum {
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'shown')
shown(r'shown'),
@JsonValue(r'paused')
paused(r'paused');

const CanvasStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


