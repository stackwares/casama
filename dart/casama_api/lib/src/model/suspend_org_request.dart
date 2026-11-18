//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suspend_org_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuspendOrgRequest {
  /// Returns a new [SuspendOrgRequest] instance.
  SuspendOrgRequest({

    required  this.reason,
  });

  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SuspendOrgRequest &&
      other.reason == reason;

    @override
    int get hashCode =>
        reason.hashCode;

  factory SuspendOrgRequest.fromJson(Map<String, dynamic> json) => _$SuspendOrgRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SuspendOrgRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

