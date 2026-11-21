//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/model_choice.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_policy.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModelPolicy {
  /// Returns a new [ModelPolicy] instance.
  ModelPolicy({

     this.source_,

     this.primary,

     this.fallbacks,

     this.cheap,
  });

      /// Where this bot gets its model (docs/OWN-KEYS-PLAN.md §6): \"workspace\" (follow the workspace default), \"casama\" (Casama's models), or \"own\" (a specific key and model)
  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final ModelPolicySource_Enum? source_;



  @JsonKey(
    
    name: r'primary',
    required: false,
    includeIfNull: false,
  )


  final ModelChoice? primary;



  @JsonKey(
    
    name: r'fallbacks',
    required: false,
    includeIfNull: false,
  )


  final List<ModelChoice>? fallbacks;



      /// Used for memory extraction, summaries and titles
  @JsonKey(
    
    name: r'cheap',
    required: false,
    includeIfNull: false,
  )


  final ModelChoice? cheap;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ModelPolicy &&
      other.source_ == source_ &&
      other.primary == primary &&
      other.fallbacks == fallbacks &&
      other.cheap == cheap;

    @override
    int get hashCode =>
        source_.hashCode +
        primary.hashCode +
        fallbacks.hashCode +
        cheap.hashCode;

  factory ModelPolicy.fromJson(Map<String, dynamic> json) => _$ModelPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$ModelPolicyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Where this bot gets its model (docs/OWN-KEYS-PLAN.md §6): \"workspace\" (follow the workspace default), \"casama\" (Casama's models), or \"own\" (a specific key and model)
enum ModelPolicySource_Enum {
    /// Where this bot gets its model (docs/OWN-KEYS-PLAN.md §6): \"workspace\" (follow the workspace default), \"casama\" (Casama's models), or \"own\" (a specific key and model)
@JsonValue(r'workspace')
workspace(r'workspace'),
    /// Where this bot gets its model (docs/OWN-KEYS-PLAN.md §6): \"workspace\" (follow the workspace default), \"casama\" (Casama's models), or \"own\" (a specific key and model)
@JsonValue(r'casama')
casama(r'casama'),
    /// Where this bot gets its model (docs/OWN-KEYS-PLAN.md §6): \"workspace\" (follow the workspace default), \"casama\" (Casama's models), or \"own\" (a specific key and model)
@JsonValue(r'own')
own(r'own');

const ModelPolicySource_Enum(this.value);

final String value;

@override
String toString() => value;
}


