//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/for_you_brief.dart';
import 'package:kasama_api/src/model/suggestion.dart';
import 'package:kasama_api/src/model/for_you_approval.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'for_you.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForYou {
  /// Returns a new [ForYou] instance.
  ForYou({

    required  this.briefs,

    required  this.suggestions,

    required  this.approvals,
  });

  @JsonKey(
    
    name: r'briefs',
    required: true,
    includeIfNull: false,
  )


  final List<ForYouBrief> briefs;



  @JsonKey(
    
    name: r'suggestions',
    required: true,
    includeIfNull: false,
  )


  final List<Suggestion> suggestions;



  @JsonKey(
    
    name: r'approvals',
    required: true,
    includeIfNull: false,
  )


  final List<ForYouApproval> approvals;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ForYou &&
      other.briefs == briefs &&
      other.suggestions == suggestions &&
      other.approvals == approvals;

    @override
    int get hashCode =>
        briefs.hashCode +
        suggestions.hashCode +
        approvals.hashCode;

  factory ForYou.fromJson(Map<String, dynamic> json) => _$ForYouFromJson(json);

  Map<String, dynamic> toJson() => _$ForYouToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

