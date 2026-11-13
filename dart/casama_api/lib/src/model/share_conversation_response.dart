//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'share_conversation_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ShareConversationResponse {
  /// Returns a new [ShareConversationResponse] instance.
  ShareConversationResponse({

    required  this.url,
  });

  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ShareConversationResponse &&
      other.url == url;

    @override
    int get hashCode =>
        (url == null ? 0 : url.hashCode);

  factory ShareConversationResponse.fromJson(Map<String, dynamic> json) => _$ShareConversationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ShareConversationResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

