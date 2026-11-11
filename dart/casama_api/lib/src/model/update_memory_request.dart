//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_memory_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateMemoryRequest {
  /// Returns a new [UpdateMemoryRequest] instance.
  UpdateMemoryRequest({

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
    bool operator ==(Object other) => identical(this, other) || other is UpdateMemoryRequest &&
      other.content == content &&
      other.pinned == pinned;

    @override
    int get hashCode =>
        content.hashCode +
        pinned.hashCode;

  factory UpdateMemoryRequest.fromJson(Map<String, dynamic> json) => _$UpdateMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMemoryRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

