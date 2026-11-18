//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/conversation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConversationList {
  /// Returns a new [ConversationList] instance.
  ConversationList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Conversation> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConversationList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ConversationList.fromJson(Map<String, dynamic> json) => _$ConversationListFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

