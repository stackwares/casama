//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/support_web_stats_gaps_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_stats.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebStats {
  /// Returns a new [SupportWebStats] instance.
  SupportWebStats({

    required  this.on_,

    required  this.messagesToday,

    required  this.usdToday,

    required  this.dailyBudgetUsd,

    required  this.pausedAddresses,

    required  this.gaps,
  });

  @JsonKey(
    
    name: r'on',
    required: true,
    includeIfNull: false,
  )


  final bool on_;



  @JsonKey(
    
    name: r'messages_today',
    required: true,
    includeIfNull: false,
  )


  final int messagesToday;



  @JsonKey(
    
    name: r'usd_today',
    required: true,
    includeIfNull: false,
  )


  final num usdToday;



  @JsonKey(
    
    name: r'daily_budget_usd',
    required: true,
    includeIfNull: false,
  )


  final num dailyBudgetUsd;



  @JsonKey(
    
    name: r'paused_addresses',
    required: true,
    includeIfNull: false,
  )


  final int pausedAddresses;



  @JsonKey(
    
    name: r'gaps',
    required: true,
    includeIfNull: false,
  )


  final List<SupportWebStatsGapsInner> gaps;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebStats &&
      other.on_ == on_ &&
      other.messagesToday == messagesToday &&
      other.usdToday == usdToday &&
      other.dailyBudgetUsd == dailyBudgetUsd &&
      other.pausedAddresses == pausedAddresses &&
      other.gaps == gaps;

    @override
    int get hashCode =>
        on_.hashCode +
        messagesToday.hashCode +
        usdToday.hashCode +
        dailyBudgetUsd.hashCode +
        pausedAddresses.hashCode +
        gaps.hashCode;

  factory SupportWebStats.fromJson(Map<String, dynamic> json) => _$SupportWebStatsFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

