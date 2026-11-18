//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/highlight.dart';
import 'package:casama_api/src/model/page_history_conversations_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_history.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageHistory {
  /// Returns a new [PageHistory] instance.
  PageHistory({

    required  this.conversations,

    required  this.highlights,
  });

  @JsonKey(
    
    name: r'conversations',
    required: true,
    includeIfNull: false,
  )


  final List<PageHistoryConversationsInner> conversations;



  @JsonKey(
    
    name: r'highlights',
    required: true,
    includeIfNull: false,
  )


  final List<Highlight> highlights;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageHistory &&
      other.conversations == conversations &&
      other.highlights == highlights;

    @override
    int get hashCode =>
        conversations.hashCode +
        highlights.hashCode;

  factory PageHistory.fromJson(Map<String, dynamic> json) => _$PageHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PageHistoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

