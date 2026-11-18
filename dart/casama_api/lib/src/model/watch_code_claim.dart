//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_code_claim.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchCodeClaim {
  /// Returns a new [WatchCodeClaim] instance.
  WatchCodeClaim({

    required  this.orgId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchCodeClaim &&
      other.orgId == orgId;

    @override
    int get hashCode =>
        orgId.hashCode;

  factory WatchCodeClaim.fromJson(Map<String, dynamic> json) => _$WatchCodeClaimFromJson(json);

  Map<String, dynamic> toJson() => _$WatchCodeClaimToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

