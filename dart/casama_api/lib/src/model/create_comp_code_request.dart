//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_comp_code_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateCompCodeRequest {
  /// Returns a new [CreateCompCodeRequest] instance.
  CreateCompCodeRequest({

    required  this.planCode,

    required  this.months,

     this.maxRedemptions = 1,

     this.redeemBy,

     this.note,
  });

  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



          // minimum: 1
          // maximum: 36
  @JsonKey(
    
    name: r'months',
    required: true,
    includeIfNull: false,
  )


  final int months;



          // minimum: 1
          // maximum: 10000
  @JsonKey(
    defaultValue: 1,
    name: r'max_redemptions',
    required: false,
    includeIfNull: false,
  )


  final int? maxRedemptions;



  @JsonKey(
    
    name: r'redeem_by',
    required: false,
    includeIfNull: false,
  )


  final DateTime? redeemBy;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateCompCodeRequest &&
      other.planCode == planCode &&
      other.months == months &&
      other.maxRedemptions == maxRedemptions &&
      other.redeemBy == redeemBy &&
      other.note == note;

    @override
    int get hashCode =>
        planCode.hashCode +
        months.hashCode +
        maxRedemptions.hashCode +
        (redeemBy == null ? 0 : redeemBy.hashCode) +
        (note == null ? 0 : note.hashCode);

  factory CreateCompCodeRequest.fromJson(Map<String, dynamic> json) => _$CreateCompCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCompCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

