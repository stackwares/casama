//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingSettings {
  /// Returns a new [BillingSettings] instance.
  BillingSettings({

    required  this.markup,
  });

      /// Multiplier on what Casama pays for usage on its own keys (1.3 = 30% over cost)
          // minimum: 1
  @JsonKey(
    
    name: r'markup',
    required: true,
    includeIfNull: false,
  )


  final num markup;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingSettings &&
      other.markup == markup;

    @override
    int get hashCode =>
        markup.hashCode;

  factory BillingSettings.fromJson(Map<String, dynamic> json) => _$BillingSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$BillingSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

