//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_asked.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchAsked {
  /// Returns a new [WatchAsked] instance.
  WatchAsked({

    required  this.conversationId,

    required  this.messageId,

    required  this.runId,

    required  this.heard,
  });

  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: true,
  )


  final String? runId;



  @JsonKey(
    
    name: r'heard',
    required: true,
    includeIfNull: false,
  )


  final String heard;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchAsked &&
      other.conversationId == conversationId &&
      other.messageId == messageId &&
      other.runId == runId &&
      other.heard == heard;

    @override
    int get hashCode =>
        conversationId.hashCode +
        messageId.hashCode +
        (runId == null ? 0 : runId.hashCode) +
        heard.hashCode;

  factory WatchAsked.fromJson(Map<String, dynamic> json) => _$WatchAskedFromJson(json);

  Map<String, dynamic> toJson() => _$WatchAskedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

