//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_conversation_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateConversationRequest {
  /// Returns a new [UpdateConversationRequest] instance.
  UpdateConversationRequest({

     this.title,

     this.pinned,
  });

      /// A new name; empty or null goes back to the automatic one
  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'pinned',
    required: false,
    includeIfNull: false,
  )


  final bool? pinned;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateConversationRequest &&
      other.title == title &&
      other.pinned == pinned;

    @override
    int get hashCode =>
        (title == null ? 0 : title.hashCode) +
        pinned.hashCode;

  factory UpdateConversationRequest.fromJson(Map<String, dynamic> json) => _$UpdateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateConversationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

