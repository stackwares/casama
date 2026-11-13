//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'share_conversation_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ShareConversationRequest {
  /// Returns a new [ShareConversationRequest] instance.
  ShareConversationRequest({

    required  this.public,
  });

  @JsonKey(
    
    name: r'public',
    required: true,
    includeIfNull: false,
  )


  final bool public;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ShareConversationRequest &&
      other.public == public;

    @override
    int get hashCode =>
        public.hashCode;

  factory ShareConversationRequest.fromJson(Map<String, dynamic> json) => _$ShareConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ShareConversationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

