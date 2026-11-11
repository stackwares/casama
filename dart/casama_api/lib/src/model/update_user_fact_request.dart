//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_user_fact_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateUserFactRequest {
  /// Returns a new [UpdateUserFactRequest] instance.
  UpdateUserFactRequest({

     this.content,

     this.pinned,
  });

  @JsonKey(
    
    name: r'content',
    required: false,
    includeIfNull: false,
  )


  final String? content;



  @JsonKey(
    
    name: r'pinned',
    required: false,
    includeIfNull: false,
  )


  final bool? pinned;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateUserFactRequest &&
      other.content == content &&
      other.pinned == pinned;

    @override
    int get hashCode =>
        content.hashCode +
        pinned.hashCode;

  factory UpdateUserFactRequest.fromJson(Map<String, dynamic> json) => _$UpdateUserFactRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserFactRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

