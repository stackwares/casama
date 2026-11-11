//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'edit_message_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EditMessageRequest {
  /// Returns a new [EditMessageRequest] instance.
  EditMessageRequest({

    required  this.text,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EditMessageRequest &&
      other.text == text;

    @override
    int get hashCode =>
        text.hashCode;

  factory EditMessageRequest.fromJson(Map<String, dynamic> json) => _$EditMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EditMessageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

