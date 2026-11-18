//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/content_report.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'content_report_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ContentReportList {
  /// Returns a new [ContentReportList] instance.
  ContentReportList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ContentReport> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ContentReportList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ContentReportList.fromJson(Map<String, dynamic> json) => _$ContentReportListFromJson(json);

  Map<String, dynamic> toJson() => _$ContentReportListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

