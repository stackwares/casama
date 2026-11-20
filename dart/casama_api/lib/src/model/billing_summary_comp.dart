//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_summary_comp.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingSummaryComp {
  /// Returns a new [BillingSummaryComp] instance.
  BillingSummaryComp({

    required  this.planCode,

    required  this.endsAt,

    required  this.from,

    required  this.keepFrom,
  });

  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



  @JsonKey(
    
    name: r'ends_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime endsAt;



  @JsonKey(
    
    name: r'from',
    required: true,
    includeIfNull: false,
  )


  final BillingSummaryCompFromEnum from;



      /// From this moment the comped plan can be bought to keep it
  @JsonKey(
    
    name: r'keep_from',
    required: true,
    includeIfNull: false,
  )


  final DateTime keepFrom;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingSummaryComp &&
      other.planCode == planCode &&
      other.endsAt == endsAt &&
      other.from == from &&
      other.keepFrom == keepFrom;

    @override
    int get hashCode =>
        planCode.hashCode +
        endsAt.hashCode +
        from.hashCode +
        keepFrom.hashCode;

  factory BillingSummaryComp.fromJson(Map<String, dynamic> json) => _$BillingSummaryCompFromJson(json);

  Map<String, dynamic> toJson() => _$BillingSummaryCompToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BillingSummaryCompFromEnum {
@JsonValue(r'grant')
grant(r'grant'),
@JsonValue(r'code')
code(r'code');

const BillingSummaryCompFromEnum(this.value);

final String value;

@override
String toString() => value;
}


