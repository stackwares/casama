//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'limit_reset_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LimitResetSettings {
  /// Returns a new [LimitResetSettings] instance.
  LimitResetSettings({

    required  this.enabled,

    required  this.perPeriod,

    required  this.maxHeld,

    required  this.notifyOwners,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



          // minimum: 1
          // maximum: 100
  @JsonKey(
    
    name: r'per_period',
    required: true,
    includeIfNull: false,
  )


  final int perPeriod;



          // minimum: 1
          // maximum: 100
  @JsonKey(
    
    name: r'max_held',
    required: true,
    includeIfNull: false,
  )


  final int maxHeld;



  @JsonKey(
    
    name: r'notify_owners',
    required: true,
    includeIfNull: false,
  )


  final bool notifyOwners;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LimitResetSettings &&
      other.enabled == enabled &&
      other.perPeriod == perPeriod &&
      other.maxHeld == maxHeld &&
      other.notifyOwners == notifyOwners;

    @override
    int get hashCode =>
        enabled.hashCode +
        perPeriod.hashCode +
        maxHeld.hashCode +
        notifyOwners.hashCode;

  factory LimitResetSettings.fromJson(Map<String, dynamic> json) => _$LimitResetSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$LimitResetSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

