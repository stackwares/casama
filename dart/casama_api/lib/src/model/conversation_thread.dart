//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_thread.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConversationThread {
  /// Returns a new [ConversationThread] instance.
  ConversationThread({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Map<String, Object?>> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConversationThread &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ConversationThread.fromJson(Map<String, dynamic> json) => _$ConversationThreadFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationThreadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

