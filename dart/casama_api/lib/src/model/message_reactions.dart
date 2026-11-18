//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/reaction_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_reactions.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageReactions {
  /// Returns a new [MessageReactions] instance.
  MessageReactions({

    required  this.messageId,

    required  this.reactions,
  });

  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;



      /// Grouped by emoji, most first
  @JsonKey(
    
    name: r'reactions',
    required: true,
    includeIfNull: false,
  )


  final List<ReactionSummary> reactions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageReactions &&
      other.messageId == messageId &&
      other.reactions == reactions;

    @override
    int get hashCode =>
        messageId.hashCode +
        reactions.hashCode;

  factory MessageReactions.fromJson(Map<String, dynamic> json) => _$MessageReactionsFromJson(json);

  Map<String, dynamic> toJson() => _$MessageReactionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

