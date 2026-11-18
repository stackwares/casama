//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_margin_by_day_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMarginByDayInner {
  /// Returns a new [AdminMarginByDayInner] instance.
  AdminMarginByDayInner({

    required  this.date,

    required  this.chargedUsd,

    required  this.chargedTrackedUsd,

    required  this.upstreamUsd,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final String date;



      /// Taken from credits for usage
  @JsonKey(
    
    name: r'charged_usd',
    required: true,
    includeIfNull: false,
  )


  final num chargedUsd;



      /// The charged part whose cost is known per row (not computers)
  @JsonKey(
    
    name: r'charged_tracked_usd',
    required: true,
    includeIfNull: false,
  )


  final num chargedTrackedUsd;



      /// What the server paid its providers, fees included, also for waived rows
  @JsonKey(
    
    name: r'upstream_usd',
    required: true,
    includeIfNull: false,
  )


  final num upstreamUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMarginByDayInner &&
      other.date == date &&
      other.chargedUsd == chargedUsd &&
      other.chargedTrackedUsd == chargedTrackedUsd &&
      other.upstreamUsd == upstreamUsd;

    @override
    int get hashCode =>
        date.hashCode +
        chargedUsd.hashCode +
        chargedTrackedUsd.hashCode +
        upstreamUsd.hashCode;

  factory AdminMarginByDayInner.fromJson(Map<String, dynamic> json) => _$AdminMarginByDayInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMarginByDayInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

