//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_message_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SendMessageRequest {
  /// Returns a new [SendMessageRequest] instance.
  SendMessageRequest({

    required  this.text,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SendMessageRequest &&
      other.text == text;

    @override
    int get hashCode =>
        text.hashCode;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) => _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

