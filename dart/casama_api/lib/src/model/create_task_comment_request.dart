//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_task_comment_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateTaskCommentRequest {
  /// Returns a new [CreateTaskCommentRequest] instance.
  CreateTaskCommentRequest({

    required  this.bodyMd,
  });

  @JsonKey(
    
    name: r'body_md',
    required: true,
    includeIfNull: false,
  )


  final String bodyMd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateTaskCommentRequest &&
      other.bodyMd == bodyMd;

    @override
    int get hashCode =>
        bodyMd.hashCode;

  factory CreateTaskCommentRequest.fromJson(Map<String, dynamic> json) => _$CreateTaskCommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTaskCommentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

