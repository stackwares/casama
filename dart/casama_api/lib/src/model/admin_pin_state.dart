//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_pin_state.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPinState {
  /// Returns a new [AdminPinState] instance.
  AdminPinState({

    required  this.set_,

    required  this.disabled,

    required  this.triesLeft,
  });

  @JsonKey(
    
    name: r'set',
    required: true,
    includeIfNull: false,
  )


  final bool set_;



  @JsonKey(
    
    name: r'disabled',
    required: true,
    includeIfNull: false,
  )


  final bool disabled;



  @JsonKey(
    
    name: r'tries_left',
    required: true,
    includeIfNull: false,
  )


  final int triesLeft;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminPinState &&
      other.set_ == set_ &&
      other.disabled == disabled &&
      other.triesLeft == triesLeft;

    @override
    int get hashCode =>
        set_.hashCode +
        disabled.hashCode +
        triesLeft.hashCode;

  factory AdminPinState.fromJson(Map<String, dynamic> json) => _$AdminPinStateFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPinStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

