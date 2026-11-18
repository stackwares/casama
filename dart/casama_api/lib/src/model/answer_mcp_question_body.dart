//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'answer_mcp_question_body.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AnswerMcpQuestionBody {
  /// Returns a new [AnswerMcpQuestionBody] instance.
  AnswerMcpQuestionBody({

    required  this.action,

     this.content,
  });

  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final AnswerMcpQuestionBodyActionEnum action;



      /// The answers, by field, when accepting: text, numbers and yes/no, checked against the question's form
  @JsonKey(
    
    name: r'content',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AnswerMcpQuestionBody &&
      other.action == action &&
      other.content == content;

    @override
    int get hashCode =>
        action.hashCode +
        content.hashCode;

  factory AnswerMcpQuestionBody.fromJson(Map<String, dynamic> json) => _$AnswerMcpQuestionBodyFromJson(json);

  Map<String, dynamic> toJson() => _$AnswerMcpQuestionBodyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AnswerMcpQuestionBodyActionEnum {
@JsonValue(r'accept')
accept(r'accept'),
@JsonValue(r'decline')
decline(r'decline'),
@JsonValue(r'cancel')
cancel(r'cancel');

const AnswerMcpQuestionBodyActionEnum(this.value);

final String value;

@override
String toString() => value;
}


