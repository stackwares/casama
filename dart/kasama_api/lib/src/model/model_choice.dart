//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_choice.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModelChoice {
  /// Returns a new [ModelChoice] instance.
  ModelChoice({

    required  this.credentialId,

    required  this.model,
  });

  @JsonKey(
    
    name: r'credential_id',
    required: true,
    includeIfNull: false,
  )


  final String credentialId;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ModelChoice &&
      other.credentialId == credentialId &&
      other.model == model;

    @override
    int get hashCode =>
        credentialId.hashCode +
        model.hashCode;

  factory ModelChoice.fromJson(Map<String, dynamic> json) => _$ModelChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$ModelChoiceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

