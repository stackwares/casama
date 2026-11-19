//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/app_mention_ref.dart';
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

     this.apps,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



      /// Connected apps picked with @ in the edited message
  @JsonKey(
    
    name: r'apps',
    required: false,
    includeIfNull: false,
  )


  final List<AppMentionRef>? apps;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EditMessageRequest &&
      other.text == text &&
      other.apps == apps;

    @override
    int get hashCode =>
        text.hashCode +
        apps.hashCode;

  factory EditMessageRequest.fromJson(Map<String, dynamic> json) => _$EditMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EditMessageRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

