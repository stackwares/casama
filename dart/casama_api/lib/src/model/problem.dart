//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/problem_errors_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'problem.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Problem {
  /// Returns a new [Problem] instance.
  Problem({

    required  this.type,

    required  this.title,

    required  this.status,

    required  this.code,

     this.detail,

     this.instance,

     this.errors,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final int status;



      /// Stable error code
  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'detail',
    required: false,
    includeIfNull: false,
  )


  final String? detail;



  @JsonKey(
    
    name: r'instance',
    required: false,
    includeIfNull: false,
  )


  final String? instance;



      /// Field errors for validation_failed
  @JsonKey(
    
    name: r'errors',
    required: false,
    includeIfNull: false,
  )


  final List<ProblemErrorsInner>? errors;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Problem &&
      other.type == type &&
      other.title == title &&
      other.status == status &&
      other.code == code &&
      other.detail == detail &&
      other.instance == instance &&
      other.errors == errors;

    @override
    int get hashCode =>
        type.hashCode +
        title.hashCode +
        status.hashCode +
        code.hashCode +
        detail.hashCode +
        instance.hashCode +
        errors.hashCode;

  factory Problem.fromJson(Map<String, dynamic> json) => _$ProblemFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

