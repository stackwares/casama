//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_teach_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveTeachRequest {
  /// Returns a new [SaveTeachRequest] instance.
  SaveTeachRequest({

    required  this.name,

    required  this.description,

    required  this.body,

     this.tryNow,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'body',
    required: true,
    includeIfNull: false,
  )


  final String body;



  @JsonKey(
    
    name: r'try_now',
    required: false,
    includeIfNull: false,
  )


  final bool? tryNow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveTeachRequest &&
      other.name == name &&
      other.description == description &&
      other.body == body &&
      other.tryNow == tryNow;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        body.hashCode +
        tryNow.hashCode;

  factory SaveTeachRequest.fromJson(Map<String, dynamic> json) => _$SaveTeachRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveTeachRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

