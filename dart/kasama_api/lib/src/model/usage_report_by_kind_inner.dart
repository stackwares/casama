//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report_by_kind_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReportByKindInner {
  /// Returns a new [UsageReportByKindInner] instance.
  UsageReportByKindInner({

    required  this.kind,

    required  this.quantity,

    required  this.costUsd,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'quantity',
    required: true,
    includeIfNull: false,
  )


  final num quantity;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageReportByKindInner &&
      other.kind == kind &&
      other.quantity == quantity &&
      other.costUsd == costUsd;

    @override
    int get hashCode =>
        kind.hashCode +
        quantity.hashCode +
        costUsd.hashCode;

  factory UsageReportByKindInner.fromJson(Map<String, dynamic> json) => _$UsageReportByKindInnerFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportByKindInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

