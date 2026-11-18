//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_analytics_opt_out_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetAnalyticsOptOutRequest {
  /// Returns a new [SetAnalyticsOptOutRequest] instance.
  SetAnalyticsOptOutRequest({

    required  this.optOut,
  });

  @JsonKey(
    
    name: r'opt_out',
    required: true,
    includeIfNull: false,
  )


  final bool optOut;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetAnalyticsOptOutRequest &&
      other.optOut == optOut;

    @override
    int get hashCode =>
        optOut.hashCode;

  factory SetAnalyticsOptOutRequest.fromJson(Map<String, dynamic> json) => _$SetAnalyticsOptOutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetAnalyticsOptOutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

