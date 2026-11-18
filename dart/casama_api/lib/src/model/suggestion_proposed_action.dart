//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestion_proposed_action.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuggestionProposedAction {
  /// Returns a new [SuggestionProposedAction] instance.
  SuggestionProposedAction({

    required  this.tool,

     this.args,
  });

  @JsonKey(
    
    name: r'tool',
    required: true,
    includeIfNull: false,
  )


  final String tool;



  @JsonKey(
    
    name: r'args',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? args;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SuggestionProposedAction &&
      other.tool == tool &&
      other.args == args;

    @override
    int get hashCode =>
        tool.hashCode +
        args.hashCode;

  factory SuggestionProposedAction.fromJson(Map<String, dynamic> json) => _$SuggestionProposedActionFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestionProposedActionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

