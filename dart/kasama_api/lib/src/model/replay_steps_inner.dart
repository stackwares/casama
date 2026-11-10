//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'replay_steps_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReplayStepsInner {
  /// Returns a new [ReplayStepsInner] instance.
  ReplayStepsInner({

    required  this.tool,

     this.note,
  });

  @JsonKey(
    
    name: r'tool',
    required: true,
    includeIfNull: false,
  )


  final String tool;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReplayStepsInner &&
      other.tool == tool &&
      other.note == note;

    @override
    int get hashCode =>
        tool.hashCode +
        note.hashCode;

  factory ReplayStepsInner.fromJson(Map<String, dynamic> json) => _$ReplayStepsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ReplayStepsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

