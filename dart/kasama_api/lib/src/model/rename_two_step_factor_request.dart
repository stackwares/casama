//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rename_two_step_factor_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RenameTwoStepFactorRequest {
  /// Returns a new [RenameTwoStepFactorRequest] instance.
  RenameTwoStepFactorRequest({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RenameTwoStepFactorRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory RenameTwoStepFactorRequest.fromJson(Map<String, dynamic> json) => _$RenameTwoStepFactorRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RenameTwoStepFactorRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

