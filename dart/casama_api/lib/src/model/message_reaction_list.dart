//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/message_reaction.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_reaction_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageReactionList {
  /// Returns a new [MessageReactionList] instance.
  MessageReactionList({

    required  this.messageId,

    required  this.items,
  });

  @JsonKey(
    
    name: r'message_id',
    required: true,
    includeIfNull: false,
  )


  final String messageId;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<MessageReaction> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageReactionList &&
      other.messageId == messageId &&
      other.items == items;

    @override
    int get hashCode =>
        messageId.hashCode +
        items.hashCode;

  factory MessageReactionList.fromJson(Map<String, dynamic> json) => _$MessageReactionListFromJson(json);

  Map<String, dynamic> toJson() => _$MessageReactionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

