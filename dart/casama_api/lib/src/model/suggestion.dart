//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/suggestion_proposed_action.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestion.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Suggestion {
  /// Returns a new [Suggestion] instance.
  Suggestion({

    required  this.id,

    required  this.botId,

    required  this.title,

    required  this.bodyMd,

    required  this.proposedAction,

    required  this.sources,

    required  this.urgency,

    required  this.expiresAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'body_md',
    required: true,
    includeIfNull: false,
  )


  final String bodyMd;



  @JsonKey(
    
    name: r'proposed_action',
    required: true,
    includeIfNull: true,
  )


  final SuggestionProposedAction? proposedAction;



  @JsonKey(
    
    name: r'sources',
    required: true,
    includeIfNull: false,
  )


  final List<String> sources;



  @JsonKey(
    
    name: r'urgency',
    required: true,
    includeIfNull: false,
  )


  final SuggestionUrgencyEnum urgency;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Suggestion &&
      other.id == id &&
      other.botId == botId &&
      other.title == title &&
      other.bodyMd == bodyMd &&
      other.proposedAction == proposedAction &&
      other.sources == sources &&
      other.urgency == urgency &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        title.hashCode +
        bodyMd.hashCode +
        (proposedAction == null ? 0 : proposedAction.hashCode) +
        sources.hashCode +
        urgency.hashCode +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory Suggestion.fromJson(Map<String, dynamic> json) => _$SuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SuggestionUrgencyEnum {
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'normal')
normal(r'normal'),
@JsonValue(r'urgent')
urgent(r'urgent');

const SuggestionUrgencyEnum(this.value);

final String value;

@override
String toString() => value;
}


