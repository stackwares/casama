//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_error.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunError {
  /// Returns a new [RunError] instance.
  RunError({

    required  this.code,

    required  this.message,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunError &&
      other.code == code &&
      other.message == message;

    @override
    int get hashCode =>
        code.hashCode +
        message.hashCode;

  factory RunError.fromJson(Map<String, dynamic> json) => _$RunErrorFromJson(json);

  Map<String, dynamic> toJson() => _$RunErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

