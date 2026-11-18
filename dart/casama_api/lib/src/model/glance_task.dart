//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_task.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceTask {
  /// Returns a new [GlanceTask] instance.
  GlanceTask({

    required  this.id,

    required  this.title,

    required  this.status,

    required  this.bot,

    required  this.link,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GlanceTaskStatusEnum status;



  @JsonKey(
    
    name: r'bot',
    required: true,
    includeIfNull: true,
  )


  final String? bot;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceTask &&
      other.id == id &&
      other.title == title &&
      other.status == status &&
      other.bot == bot &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        status.hashCode +
        (bot == null ? 0 : bot.hashCode) +
        link.hashCode;

  factory GlanceTask.fromJson(Map<String, dynamic> json) => _$GlanceTaskFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceTaskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GlanceTaskStatusEnum {
@JsonValue(r'todo')
todo(r'todo'),
@JsonValue(r'in_progress')
inProgress(r'in_progress'),
@JsonValue(r'in_review')
inReview(r'in_review'),
@JsonValue(r'blocked')
blocked(r'blocked'),
@JsonValue(r'done')
done(r'done');

const GlanceTaskStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


