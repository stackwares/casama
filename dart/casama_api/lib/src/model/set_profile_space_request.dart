//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_profile_space_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetProfileSpaceRequest {
  /// Returns a new [SetProfileSpaceRequest] instance.
  SetProfileSpaceRequest({

    required  this.shared,
  });

  @JsonKey(
    
    name: r'shared',
    required: true,
    includeIfNull: false,
  )


  final bool shared;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetProfileSpaceRequest &&
      other.shared == shared;

    @override
    int get hashCode =>
        shared.hashCode;

  factory SetProfileSpaceRequest.fromJson(Map<String, dynamic> json) => _$SetProfileSpaceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetProfileSpaceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

