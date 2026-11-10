//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teach_draft_inputs_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachDraftInputsInner {
  /// Returns a new [TeachDraftInputsInner] instance.
  TeachDraftInputsInner({

    required  this.name,

     this.description,

     this.secret,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'secret',
    required: false,
    includeIfNull: false,
  )


  final bool? secret;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TeachDraftInputsInner &&
      other.name == name &&
      other.description == description &&
      other.secret == secret;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        secret.hashCode;

  factory TeachDraftInputsInner.fromJson(Map<String, dynamic> json) => _$TeachDraftInputsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$TeachDraftInputsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

