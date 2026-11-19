//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'call_step_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CallStepResult {
  /// Returns a new [CallStepResult] instance.
  CallStepResult({

    required  this.runId,
  });

      /// The chat run a started step became
  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: true,
  )


  final String? runId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CallStepResult &&
      other.runId == runId;

    @override
    int get hashCode =>
        (runId == null ? 0 : runId.hashCode);

  factory CallStepResult.fromJson(Map<String, dynamic> json) => _$CallStepResultFromJson(json);

  Map<String, dynamic> toJson() => _$CallStepResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

