//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'call_step_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CallStepRequest {
  /// Returns a new [CallStepRequest] instance.
  CallStepRequest({

    required  this.action,
  });

  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final CallStepRequestActionEnum action;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CallStepRequest &&
      other.action == action;

    @override
    int get hashCode =>
        action.hashCode;

  factory CallStepRequest.fromJson(Map<String, dynamic> json) => _$CallStepRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CallStepRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CallStepRequestActionEnum {
@JsonValue(r'start')
start(r'start'),
@JsonValue(r'dismiss')
dismiss(r'dismiss');

const CallStepRequestActionEnum(this.value);

final String value;

@override
String toString() => value;
}


