//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_checkins.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotCheckins {
  /// Returns a new [BotCheckins] instance.
  BotCheckins({

    required  this.enabled,

    required  this.briefTime,

    required  this.scanEveryHours,

    required  this.dailyCapUsd,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



      /// Local time, HH:MM
  @JsonKey(
    
    name: r'brief_time',
    required: true,
    includeIfNull: false,
  )


  final String briefTime;



          // minimum: 1
          // maximum: 24
  @JsonKey(
    
    name: r'scan_every_hours',
    required: true,
    includeIfNull: false,
  )


  final int scanEveryHours;



          // minimum: 0
          // maximum: 100
  @JsonKey(
    
    name: r'daily_cap_usd',
    required: true,
    includeIfNull: false,
  )


  final num dailyCapUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotCheckins &&
      other.enabled == enabled &&
      other.briefTime == briefTime &&
      other.scanEveryHours == scanEveryHours &&
      other.dailyCapUsd == dailyCapUsd;

    @override
    int get hashCode =>
        enabled.hashCode +
        briefTime.hashCode +
        scanEveryHours.hashCode +
        dailyCapUsd.hashCode;

  factory BotCheckins.fromJson(Map<String, dynamic> json) => _$BotCheckinsFromJson(json);

  Map<String, dynamic> toJson() => _$BotCheckinsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

