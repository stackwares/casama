//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_rule_target.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionRuleTarget {
  /// Returns a new [ActionRuleTarget] instance.
  ActionRuleTarget({

     this.domains,

     this.recipients,

     this.maxAmount,
  });

  @JsonKey(
    
    name: r'domains',
    required: false,
    includeIfNull: false,
  )


  final List<String>? domains;



  @JsonKey(
    
    name: r'recipients',
    required: false,
    includeIfNull: false,
  )


  final List<String>? recipients;



          // minimum: 0
  @JsonKey(
    
    name: r'max_amount',
    required: false,
    includeIfNull: false,
  )


  final num? maxAmount;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActionRuleTarget &&
      other.domains == domains &&
      other.recipients == recipients &&
      other.maxAmount == maxAmount;

    @override
    int get hashCode =>
        domains.hashCode +
        recipients.hashCode +
        maxAmount.hashCode;

  factory ActionRuleTarget.fromJson(Map<String, dynamic> json) => _$ActionRuleTargetFromJson(json);

  Map<String, dynamic> toJson() => _$ActionRuleTargetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

