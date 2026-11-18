//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/run_status.dart';
import 'package:casama_api/src/model/run_usage_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_usage.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunUsage {
  /// Returns a new [RunUsage] instance.
  RunUsage({

    required  this.runId,

    required  this.status,

    required  this.costUsd,

    required  this.chargedUsd,

     this.upstreamCostUsd,

    required  this.tokensIn,

    required  this.tokensOut,

    required  this.durationMs,

    required  this.toolCalls,

    required  this.subruns,

    required  this.items,
  });

  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final RunStatus status;



      /// Everything metered, including your own keys
  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



      /// The part taken from Casama credits (1 credit = $1)
  @JsonKey(
    
    name: r'charged_usd',
    required: true,
    includeIfNull: false,
  )


  final num chargedUsd;



      /// Instance owner only (D-395): what the server paid its providers for this usage, fees included. Absent for everyone else; null when nothing ran on the server's keys
  @JsonKey(
    
    name: r'upstream_cost_usd',
    required: false,
    includeIfNull: false,
  )


  final num? upstreamCostUsd;



  @JsonKey(
    
    name: r'tokens_in',
    required: true,
    includeIfNull: false,
  )


  final int tokensIn;



  @JsonKey(
    
    name: r'tokens_out',
    required: true,
    includeIfNull: false,
  )


  final int tokensOut;



  @JsonKey(
    
    name: r'duration_ms',
    required: true,
    includeIfNull: true,
  )


  final int? durationMs;



  @JsonKey(
    
    name: r'tool_calls',
    required: true,
    includeIfNull: false,
  )


  final int toolCalls;



  @JsonKey(
    
    name: r'subruns',
    required: true,
    includeIfNull: false,
  )


  final int subruns;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<RunUsageItemsInner> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunUsage &&
      other.runId == runId &&
      other.status == status &&
      other.costUsd == costUsd &&
      other.chargedUsd == chargedUsd &&
      other.upstreamCostUsd == upstreamCostUsd &&
      other.tokensIn == tokensIn &&
      other.tokensOut == tokensOut &&
      other.durationMs == durationMs &&
      other.toolCalls == toolCalls &&
      other.subruns == subruns &&
      other.items == items;

    @override
    int get hashCode =>
        runId.hashCode +
        status.hashCode +
        costUsd.hashCode +
        chargedUsd.hashCode +
        (upstreamCostUsd == null ? 0 : upstreamCostUsd.hashCode) +
        tokensIn.hashCode +
        tokensOut.hashCode +
        (durationMs == null ? 0 : durationMs.hashCode) +
        toolCalls.hashCode +
        subruns.hashCode +
        items.hashCode;

  factory RunUsage.fromJson(Map<String, dynamic> json) => _$RunUsageFromJson(json);

  Map<String, dynamic> toJson() => _$RunUsageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

