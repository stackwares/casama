//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accepted_suggestion.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcceptedSuggestion {
  /// Returns a new [AcceptedSuggestion] instance.
  AcceptedSuggestion({

    required  this.conversationId,

    required  this.runId,
  });

  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AcceptedSuggestion &&
      other.conversationId == conversationId &&
      other.runId == runId;

    @override
    int get hashCode =>
        conversationId.hashCode +
        runId.hashCode;

  factory AcceptedSuggestion.fromJson(Map<String, dynamic> json) => _$AcceptedSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptedSuggestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

