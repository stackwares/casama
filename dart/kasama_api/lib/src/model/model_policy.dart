//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/model_choice.dart';
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

     this.primary,

     this.fallbacks,

     this.cheap,
  });

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
      other.primary == primary &&
      other.fallbacks == fallbacks &&
      other.cheap == cheap;

    @override
    int get hashCode =>
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

