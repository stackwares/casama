//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_org_limits_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetOrgLimitsRequest {
  /// Returns a new [SetOrgLimitsRequest] instance.
  SetOrgLimitsRequest({

    required  this.limits,
  });

      /// For example {max_bots, max_computers, monthly_usd}; replaces the org's limits
  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, num> limits;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetOrgLimitsRequest &&
      other.limits == limits;

    @override
    int get hashCode =>
        limits.hashCode;

  factory SetOrgLimitsRequest.fromJson(Map<String, dynamic> json) => _$SetOrgLimitsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetOrgLimitsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

