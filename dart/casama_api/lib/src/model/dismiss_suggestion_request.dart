//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dismiss_suggestion_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DismissSuggestionRequest {
  /// Returns a new [DismissSuggestionRequest] instance.
  DismissSuggestionRequest({

     this.dontSuggestAgain = false,
  });

  @JsonKey(
    defaultValue: false,
    name: r'dont_suggest_again',
    required: false,
    includeIfNull: false,
  )


  final bool? dontSuggestAgain;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DismissSuggestionRequest &&
      other.dontSuggestAgain == dontSuggestAgain;

    @override
    int get hashCode =>
        dontSuggestAgain.hashCode;

  factory DismissSuggestionRequest.fromJson(Map<String, dynamic> json) => _$DismissSuggestionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DismissSuggestionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

