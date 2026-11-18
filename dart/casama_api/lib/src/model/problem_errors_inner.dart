//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'problem_errors_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProblemErrorsInner {
  /// Returns a new [ProblemErrorsInner] instance.
  ProblemErrorsInner({

    required  this.path,

    required  this.message,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProblemErrorsInner &&
      other.path == path &&
      other.message == message;

    @override
    int get hashCode =>
        path.hashCode +
        message.hashCode;

  factory ProblemErrorsInner.fromJson(Map<String, dynamic> json) => _$ProblemErrorsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemErrorsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

