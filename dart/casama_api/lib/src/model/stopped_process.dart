//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stopped_process.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StoppedProcess {
  /// Returns a new [StoppedProcess] instance.
  StoppedProcess({

    required  this.stopped,
  });

  @JsonKey(
    
    name: r'stopped',
    required: true,
    includeIfNull: false,
  )


  final int stopped;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StoppedProcess &&
      other.stopped == stopped;

    @override
    int get hashCode =>
        stopped.hashCode;

  factory StoppedProcess.fromJson(Map<String, dynamic> json) => _$StoppedProcessFromJson(json);

  Map<String, dynamic> toJson() => _$StoppedProcessToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

