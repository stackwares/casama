//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_update_preview_runs_per_week.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackUpdatePreviewRunsPerWeek {
  /// Returns a new [PackUpdatePreviewRunsPerWeek] instance.
  PackUpdatePreviewRunsPerWeek({

    required  this.from,

    required  this.to,
  });

  @JsonKey(
    
    name: r'from',
    required: true,
    includeIfNull: false,
  )


  final num from;



  @JsonKey(
    
    name: r'to',
    required: true,
    includeIfNull: false,
  )


  final num to;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackUpdatePreviewRunsPerWeek &&
      other.from == from &&
      other.to == to;

    @override
    int get hashCode =>
        from.hashCode +
        to.hashCode;

  factory PackUpdatePreviewRunsPerWeek.fromJson(Map<String, dynamic> json) => _$PackUpdatePreviewRunsPerWeekFromJson(json);

  Map<String, dynamic> toJson() => _$PackUpdatePreviewRunsPerWeekToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

