//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_page_command_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePageCommandRequest {
  /// Returns a new [UpdatePageCommandRequest] instance.
  UpdatePageCommandRequest({

     this.name,

     this.prompt,

     this.position,
  });

      /// What follows / in the panel
  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'prompt',
    required: false,
    includeIfNull: false,
  )


  final String? prompt;



          // minimum: 0
          // maximum: 1000
  @JsonKey(
    
    name: r'position',
    required: false,
    includeIfNull: false,
  )


  final int? position;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePageCommandRequest &&
      other.name == name &&
      other.prompt == prompt &&
      other.position == position;

    @override
    int get hashCode =>
        name.hashCode +
        prompt.hashCode +
        position.hashCode;

  factory UpdatePageCommandRequest.fromJson(Map<String, dynamic> json) => _$UpdatePageCommandRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePageCommandRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

