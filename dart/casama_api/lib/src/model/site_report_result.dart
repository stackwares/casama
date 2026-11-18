//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_report_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteReportResult {
  /// Returns a new [SiteReportResult] instance.
  SiteReportResult({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteReportResult &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory SiteReportResult.fromJson(Map<String, dynamic> json) => _$SiteReportResultFromJson(json);

  Map<String, dynamic> toJson() => _$SiteReportResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

