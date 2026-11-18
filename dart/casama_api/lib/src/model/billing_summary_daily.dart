//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_summary_daily.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingSummaryDaily {
  /// Returns a new [BillingSummaryDaily] instance.
  BillingSummaryDaily({

    required  this.usedUsd,

    required  this.capUsd,

    required  this.resetsAt,
  });

      /// Spent today (UTC) on the server's keys
  @JsonKey(
    
    name: r'used_usd',
    required: true,
    includeIfNull: false,
  )


  final num usedUsd;



      /// The plan's daily cap on the server's keys
  @JsonKey(
    
    name: r'cap_usd',
    required: true,
    includeIfNull: false,
  )


  final num capUsd;



      /// Next midnight UTC, when the day's spend resets
  @JsonKey(
    
    name: r'resets_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime resetsAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingSummaryDaily &&
      other.usedUsd == usedUsd &&
      other.capUsd == capUsd &&
      other.resetsAt == resetsAt;

    @override
    int get hashCode =>
        usedUsd.hashCode +
        capUsd.hashCode +
        resetsAt.hashCode;

  factory BillingSummaryDaily.fromJson(Map<String, dynamic> json) => _$BillingSummaryDailyFromJson(json);

  Map<String, dynamic> toJson() => _$BillingSummaryDailyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

