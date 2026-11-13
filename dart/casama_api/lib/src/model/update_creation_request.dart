//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_creation_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateCreationRequest {
  /// Returns a new [UpdateCreationRequest] instance.
  UpdateCreationRequest({

     this.title,

     this.label,

     this.pinned,

     this.opened,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final String? label;



  @JsonKey(
    
    name: r'pinned',
    required: false,
    includeIfNull: false,
  )


  final bool? pinned;



      /// Marks it opened now (Recently opened)
  @JsonKey(
    
    name: r'opened',
    required: false,
    includeIfNull: false,
  )


  final bool? opened;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCreationRequest &&
      other.title == title &&
      other.label == label &&
      other.pinned == pinned &&
      other.opened == opened;

    @override
    int get hashCode =>
        title.hashCode +
        (label == null ? 0 : label.hashCode) +
        pinned.hashCode +
        opened.hashCode;

  factory UpdateCreationRequest.fromJson(Map<String, dynamic> json) => _$UpdateCreationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCreationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

