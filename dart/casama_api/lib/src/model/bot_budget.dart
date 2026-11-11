//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_budget.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotBudget {
  /// Returns a new [BotBudget] instance.
  BotBudget({

     this.perRunUsd,

     this.dailyUsd,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'per_run_usd',
    required: false,
    includeIfNull: false,
  )


  final num? perRunUsd;



          // minimum: 0
  @JsonKey(
    
    name: r'daily_usd',
    required: false,
    includeIfNull: false,
  )


  final num? dailyUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotBudget &&
      other.perRunUsd == perRunUsd &&
      other.dailyUsd == dailyUsd;

    @override
    int get hashCode =>
        perRunUsd.hashCode +
        dailyUsd.hashCode;

  factory BotBudget.fromJson(Map<String, dynamic> json) => _$BotBudgetFromJson(json);

  Map<String, dynamic> toJson() => _$BotBudgetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

