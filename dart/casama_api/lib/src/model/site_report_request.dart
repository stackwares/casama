//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_report_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteReportRequest {
  /// Returns a new [SiteReportRequest] instance.
  SiteReportRequest({

    required  this.address,

    required  this.reason,
  });

  @JsonKey(
    
    name: r'address',
    required: true,
    includeIfNull: false,
  )


  final String address;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteReportRequest &&
      other.address == address &&
      other.reason == reason;

    @override
    int get hashCode =>
        address.hashCode +
        reason.hashCode;

  factory SiteReportRequest.fromJson(Map<String, dynamic> json) => _$SiteReportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SiteReportRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

