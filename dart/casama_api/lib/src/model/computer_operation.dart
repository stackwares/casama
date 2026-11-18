//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_operation.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerOperation {
  /// Returns a new [ComputerOperation] instance.
  ComputerOperation({

    required  this.kind,

    required  this.step,

    required  this.checkpointId,

    required  this.error,

    required  this.startedAt,

    required  this.finishedAt,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ComputerOperationKindEnum kind;



  @JsonKey(
    
    name: r'step',
    required: true,
    includeIfNull: false,
  )


  final ComputerOperationStepEnum step;



      /// The restore point saved first: restoring it undoes the reset
  @JsonKey(
    
    name: r'checkpoint_id',
    required: true,
    includeIfNull: true,
  )


  final String? checkpointId;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;



  @JsonKey(
    
    name: r'started_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime startedAt;



  @JsonKey(
    
    name: r'finished_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? finishedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerOperation &&
      other.kind == kind &&
      other.step == step &&
      other.checkpointId == checkpointId &&
      other.error == error &&
      other.startedAt == startedAt &&
      other.finishedAt == finishedAt;

    @override
    int get hashCode =>
        kind.hashCode +
        step.hashCode +
        (checkpointId == null ? 0 : checkpointId.hashCode) +
        (error == null ? 0 : error.hashCode) +
        startedAt.hashCode +
        (finishedAt == null ? 0 : finishedAt.hashCode);

  factory ComputerOperation.fromJson(Map<String, dynamic> json) => _$ComputerOperationFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerOperationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ComputerOperationKindEnum {
@JsonValue(r'reset_system')
resetSystem(r'reset_system'),
@JsonValue(r'erase')
erase(r'erase');

const ComputerOperationKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum ComputerOperationStepEnum {
@JsonValue(r'saving')
saving(r'saving'),
@JsonValue(r'wiping')
wiping(r'wiping'),
@JsonValue(r'restarting')
restarting(r'restarting'),
@JsonValue(r'done')
done(r'done'),
@JsonValue(r'failed')
failed(r'failed');

const ComputerOperationStepEnum(this.value);

final String value;

@override
String toString() => value;
}


