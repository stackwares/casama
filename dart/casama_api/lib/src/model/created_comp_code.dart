//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_comp_code.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatedCompCode {
  /// Returns a new [CreatedCompCode] instance.
  CreatedCompCode({

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

    required  this.code,

    required  this.link,
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



      /// The code, shown only now: G-XXXXX-XXXXX
  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



      /// casama.ai/g/<code>
  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatedCompCode &&
      other.id == id &&
      other.hint == hint &&
      other.planCode == planCode &&
      other.months == months &&
      other.maxRedemptions == maxRedemptions &&
      other.redeemedCount == redeemedCount &&
      other.redeemBy == redeemBy &&
      other.note == note &&
      other.disabled == disabled &&
      other.createdAt == createdAt &&
      other.code == code &&
      other.link == link;

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
        createdAt.hashCode +
        code.hashCode +
        link.hashCode;

  factory CreatedCompCode.fromJson(Map<String, dynamic> json) => _$CreatedCompCodeFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedCompCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

