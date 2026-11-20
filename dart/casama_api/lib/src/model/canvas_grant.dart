//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_grant.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasGrant {
  /// Returns a new [CanvasGrant] instance.
  CanvasGrant({

    required  this.botId,

    required  this.bot,

    required  this.createdAt,
  });

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
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasGrant &&
      other.botId == botId &&
      other.bot == bot &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        botId.hashCode +
        bot.hashCode +
        createdAt.hashCode;

  factory CanvasGrant.fromJson(Map<String, dynamic> json) => _$CanvasGrantFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasGrantToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

