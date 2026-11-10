//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/conversation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_chat_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GroupChatList {
  /// Returns a new [GroupChatList] instance.
  GroupChatList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Conversation> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GroupChatList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GroupChatList.fromJson(Map<String, dynamic> json) => _$GroupChatListFromJson(json);

  Map<String, dynamic> toJson() => _$GroupChatListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

