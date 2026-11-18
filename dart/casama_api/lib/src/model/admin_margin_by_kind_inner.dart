//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_margin_by_kind_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMarginByKindInner {
  /// Returns a new [AdminMarginByKindInner] instance.
  AdminMarginByKindInner({

    required  this.kind,

    required  this.chargedUsd,

    required  this.chargedTrackedUsd,

    required  this.upstreamUsd,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



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
    bool operator ==(Object other) => identical(this, other) || other is AdminMarginByKindInner &&
      other.kind == kind &&
      other.chargedUsd == chargedUsd &&
      other.chargedTrackedUsd == chargedTrackedUsd &&
      other.upstreamUsd == upstreamUsd;

    @override
    int get hashCode =>
        kind.hashCode +
        chargedUsd.hashCode +
        chargedTrackedUsd.hashCode +
        upstreamUsd.hashCode;

  factory AdminMarginByKindInner.fromJson(Map<String, dynamic> json) => _$AdminMarginByKindInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMarginByKindInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

