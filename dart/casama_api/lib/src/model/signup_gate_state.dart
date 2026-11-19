//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/signup_gate.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'signup_gate_state.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupGateState {
  /// Returns a new [SignupGateState] instance.
  SignupGateState({

    required  this.gate,

    required  this.closed,
  });

  @JsonKey(
    
    name: r'gate',
    required: true,
    includeIfNull: false,
  )


  final SignupGate gate;



  @JsonKey(
    
    name: r'closed',
    required: true,
    includeIfNull: false,
  )


  final bool closed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SignupGateState &&
      other.gate == gate &&
      other.closed == closed;

    @override
    int get hashCode =>
        gate.hashCode +
        closed.hashCode;

  factory SignupGateState.fromJson(Map<String, dynamic> json) => _$SignupGateStateFromJson(json);

  Map<String, dynamic> toJson() => _$SignupGateStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

