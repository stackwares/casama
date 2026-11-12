//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reset_computer_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ResetComputerRequest {
  /// Returns a new [ResetComputerRequest] instance.
  ResetComputerRequest({

    required  this.mode,

     this.checkpoint,
  });

      /// system: a fresh system, ~/workspace kept. erase: everything removed, like a new computer.
  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final ResetComputerRequestModeEnum mode;



      /// Save a restore point first (default true)
  @JsonKey(
    
    name: r'checkpoint',
    required: false,
    includeIfNull: false,
  )


  final bool? checkpoint;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ResetComputerRequest &&
      other.mode == mode &&
      other.checkpoint == checkpoint;

    @override
    int get hashCode =>
        mode.hashCode +
        checkpoint.hashCode;

  factory ResetComputerRequest.fromJson(Map<String, dynamic> json) => _$ResetComputerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResetComputerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// system: a fresh system, ~/workspace kept. erase: everything removed, like a new computer.
enum ResetComputerRequestModeEnum {
    /// system: a fresh system, ~/workspace kept. erase: everything removed, like a new computer.
@JsonValue(r'system')
system(r'system'),
    /// system: a fresh system, ~/workspace kept. erase: everything removed, like a new computer.
@JsonValue(r'erase')
erase(r'erase');

const ResetComputerRequestModeEnum(this.value);

final String value;

@override
String toString() => value;
}


