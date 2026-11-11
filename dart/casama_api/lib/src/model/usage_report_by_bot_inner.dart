//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report_by_bot_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReportByBotInner {
  /// Returns a new [UsageReportByBotInner] instance.
  UsageReportByBotInner({

    required  this.botId,

    required  this.name,

    required  this.costUsd,

    required  this.tokensIn,

    required  this.tokensOut,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: true,
  )


  final String? name;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageReportByBotInner &&
      other.botId == botId &&
      other.name == name &&
      other.costUsd == costUsd &&
      other.tokensIn == tokensIn &&
      other.tokensOut == tokensOut;

    @override
    int get hashCode =>
        (botId == null ? 0 : botId.hashCode) +
        (name == null ? 0 : name.hashCode) +
        costUsd.hashCode +
        tokensIn.hashCode +
        tokensOut.hashCode;

  factory UsageReportByBotInner.fromJson(Map<String, dynamic> json) => _$UsageReportByBotInnerFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportByBotInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

