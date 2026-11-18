//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/chat_starter.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_starters.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChatStarters {
  /// Returns a new [ChatStarters] instance.
  ChatStarters({

    required  this.items,

    required  this.source_,

    required  this.refreshing,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ChatStarter> items;



      /// ai: a model wrote them for this person; rules: picked without a model.
  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final ChatStartersSource_Enum source_;



      /// A new list is being written; ask again in a few seconds to get it.
  @JsonKey(
    
    name: r'refreshing',
    required: true,
    includeIfNull: false,
  )


  final bool refreshing;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChatStarters &&
      other.items == items &&
      other.source_ == source_ &&
      other.refreshing == refreshing;

    @override
    int get hashCode =>
        items.hashCode +
        source_.hashCode +
        refreshing.hashCode;

  factory ChatStarters.fromJson(Map<String, dynamic> json) => _$ChatStartersFromJson(json);

  Map<String, dynamic> toJson() => _$ChatStartersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// ai: a model wrote them for this person; rules: picked without a model.
enum ChatStartersSource_Enum {
    /// ai: a model wrote them for this person; rules: picked without a model.
@JsonValue(r'ai')
ai(r'ai'),
    /// ai: a model wrote them for this person; rules: picked without a model.
@JsonValue(r'rules')
rules(r'rules');

const ChatStartersSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


