//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/teach_draft_inputs_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teach_draft.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachDraft {
  /// Returns a new [TeachDraft] instance.
  TeachDraft({

    required  this.name,

    required  this.description,

    required  this.body,

    required  this.inputs,

    required  this.checks,
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
    
    name: r'inputs',
    required: true,
    includeIfNull: false,
  )


  final List<TeachDraftInputsInner> inputs;



  @JsonKey(
    
    name: r'checks',
    required: true,
    includeIfNull: false,
  )


  final List<String> checks;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TeachDraft &&
      other.name == name &&
      other.description == description &&
      other.body == body &&
      other.inputs == inputs &&
      other.checks == checks;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        body.hashCode +
        inputs.hashCode +
        checks.hashCode;

  factory TeachDraft.fromJson(Map<String, dynamic> json) => _$TeachDraftFromJson(json);

  Map<String, dynamic> toJson() => _$TeachDraftToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

