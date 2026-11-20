//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'limit_reset_audience.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LimitResetAudience {
  /// Returns a new [LimitResetAudience] instance.
  LimitResetAudience({

     this.planCodes = const [],

     this.createdBefore,

     this.limitedWithinDays,

     this.workspaceIds = const [],
  });

  @JsonKey(
    defaultValue: [],
    name: r'plan_codes',
    required: false,
    includeIfNull: false,
  )


  final List<String>? planCodes;



  @JsonKey(
    
    name: r'created_before',
    required: false,
    includeIfNull: false,
  )


  final DateTime? createdBefore;



          // minimum: 1
          // maximum: 365
  @JsonKey(
    
    name: r'limited_within_days',
    required: false,
    includeIfNull: false,
  )


  final int? limitedWithinDays;



  @JsonKey(
    defaultValue: [],
    name: r'workspace_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? workspaceIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LimitResetAudience &&
      other.planCodes == planCodes &&
      other.createdBefore == createdBefore &&
      other.limitedWithinDays == limitedWithinDays &&
      other.workspaceIds == workspaceIds;

    @override
    int get hashCode =>
        planCodes.hashCode +
        (createdBefore == null ? 0 : createdBefore.hashCode) +
        (limitedWithinDays == null ? 0 : limitedWithinDays.hashCode) +
        workspaceIds.hashCode;

  factory LimitResetAudience.fromJson(Map<String, dynamic> json) => _$LimitResetAudienceFromJson(json);

  Map<String, dynamic> toJson() => _$LimitResetAudienceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

