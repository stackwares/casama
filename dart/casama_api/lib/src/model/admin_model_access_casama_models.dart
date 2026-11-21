//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_model_access_casama_models.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminModelAccessCasamaModels {
  /// Returns a new [AdminModelAccessCasamaModels] instance.
  AdminModelAccessCasamaModels({

    required  this.default_,

    required  this.plans,
  });

      /// Default state for any plan not listed in plans.
  @JsonKey(
    
    name: r'default',
    required: true,
    includeIfNull: false,
  )


  final AdminModelAccessCasamaModelsDefault_Enum default_;



      /// Per-plan override (for example { free: 'off' }).
  @JsonKey(
    
    name: r'plans',
    required: true,
    includeIfNull: false,
  )


  final Map<String, AdminModelAccessCasamaModelsPlansEnum> plans;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminModelAccessCasamaModels &&
      other.default_ == default_ &&
      other.plans == plans;

    @override
    int get hashCode =>
        default_.hashCode +
        plans.hashCode;

  factory AdminModelAccessCasamaModels.fromJson(Map<String, dynamic> json) => _$AdminModelAccessCasamaModelsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminModelAccessCasamaModelsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Default state for any plan not listed in plans.
enum AdminModelAccessCasamaModelsDefault_Enum {
    /// Default state for any plan not listed in plans.
@JsonValue(r'on')
on_(r'on'),
    /// Default state for any plan not listed in plans.
@JsonValue(r'off')
off(r'off');

const AdminModelAccessCasamaModelsDefault_Enum(this.value);

final String value;

@override
String toString() => value;
}



enum AdminModelAccessCasamaModelsPlansEnum {
@JsonValue(r'on')
on_(r'on'),
@JsonValue(r'off')
off(r'off');

const AdminModelAccessCasamaModelsPlansEnum(this.value);

final String value;

@override
String toString() => value;
}


