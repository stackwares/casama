//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comp_code.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CompCode {
  /// Returns a new [CompCode] instance.
  CompCode({

    required  this.id,

    required  this.hint,

    required  this.planCode,

    required  this.months,

    required  this.maxRedemptions,

    required  this.redeemedCount,

    required  this.redeemBy,

    required  this.note,

    required  this.disabled,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// The code's last characters, like …7KQ2
  @JsonKey(
    
    name: r'hint',
    required: true,
    includeIfNull: false,
  )


  final String hint;



  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



  @JsonKey(
    
    name: r'months',
    required: true,
    includeIfNull: false,
  )


  final int months;



  @JsonKey(
    
    name: r'max_redemptions',
    required: true,
    includeIfNull: false,
  )


  final int maxRedemptions;



  @JsonKey(
    
    name: r'redeemed_count',
    required: true,
    includeIfNull: false,
  )


  final int redeemedCount;



  @JsonKey(
    
    name: r'redeem_by',
    required: true,
    includeIfNull: true,
  )


  final DateTime? redeemBy;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'disabled',
    required: true,
    includeIfNull: false,
  )


  final bool disabled;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CompCode &&
      other.id == id &&
      other.hint == hint &&
      other.planCode == planCode &&
      other.months == months &&
      other.maxRedemptions == maxRedemptions &&
      other.redeemedCount == redeemedCount &&
      other.redeemBy == redeemBy &&
      other.note == note &&
      other.disabled == disabled &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        hint.hashCode +
        planCode.hashCode +
        months.hashCode +
        maxRedemptions.hashCode +
        redeemedCount.hashCode +
        (redeemBy == null ? 0 : redeemBy.hashCode) +
        (note == null ? 0 : note.hashCode) +
        disabled.hashCode +
        createdAt.hashCode;

  factory CompCode.fromJson(Map<String, dynamic> json) => _$CompCodeFromJson(json);

  Map<String, dynamic> toJson() => _$CompCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

