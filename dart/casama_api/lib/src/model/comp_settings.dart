//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comp_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompSettings {
  /// Returns a new [CompSettings] instance.
  CompSettings({

    required  this.enabled,

    required  this.grantPlans,

    required  this.codePlans,

    required  this.maxMonths,

    required  this.maxActive,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



      /// Plans an instance owner may give directly (monthly paid plans only)
  @JsonKey(
    
    name: r'grant_plans',
    required: true,
    includeIfNull: false,
  )


  final List<String> grantPlans;



      /// Plans a gift code may carry (monthly paid plans only)
  @JsonKey(
    
    name: r'code_plans',
    required: true,
    includeIfNull: false,
  )


  final List<String> codePlans;



          // minimum: 1
          // maximum: 36
  @JsonKey(
    
    name: r'max_months',
    required: true,
    includeIfNull: false,
  )


  final int maxMonths;



          // minimum: 1
          // maximum: 100000
  @JsonKey(
    
    name: r'max_active',
    required: true,
    includeIfNull: false,
  )


  final int maxActive;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CompSettings &&
      other.enabled == enabled &&
      other.grantPlans == grantPlans &&
      other.codePlans == codePlans &&
      other.maxMonths == maxMonths &&
      other.maxActive == maxActive;

    @override
    int get hashCode =>
        enabled.hashCode +
        grantPlans.hashCode +
        codePlans.hashCode +
        maxMonths.hashCode +
        maxActive.hashCode;

  factory CompSettings.fromJson(Map<String, dynamic> json) => _$CompSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CompSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

