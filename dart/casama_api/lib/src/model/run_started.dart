//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_started.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunStarted {
  /// Returns a new [RunStarted] instance.
  RunStarted({

    required  this.runId,
  });

  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunStarted &&
      other.runId == runId;

    @override
    int get hashCode =>
        runId.hashCode;

  factory RunStarted.fromJson(Map<String, dynamic> json) => _$RunStartedFromJson(json);

  Map<String, dynamic> toJson() => _$RunStartedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

