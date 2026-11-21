//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_browser_numbers.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppBrowserNumbers {
  /// Returns a new [AppBrowserNumbers] instance.
  AppBrowserNumbers({

    required  this.days,

    required  this.blockedRuns,

    required  this.blockedPeople,

    required  this.watchedBrowserRuns,

    required  this.phoneRuns,

    required  this.phonePeople,

    required  this.phonesPaired,

    required  this.phonesWithSites,

    required  this.refusedSteps,
  });

  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final int days;



      /// Runs whose computer browser met a block page while someone had the chat open
  @JsonKey(
    
    name: r'blocked_runs',
    required: true,
    includeIfNull: false,
  )


  final int blockedRuns;



  @JsonKey(
    
    name: r'blocked_people',
    required: true,
    includeIfNull: false,
  )


  final int blockedPeople;



      /// Runs that browsed on the computer while someone had the chat open
  @JsonKey(
    
    name: r'watched_browser_runs',
    required: true,
    includeIfNull: false,
  )


  final int watchedBrowserRuns;



      /// Runs that used a phone's browser
  @JsonKey(
    
    name: r'phone_runs',
    required: true,
    includeIfNull: false,
  )


  final int phoneRuns;



  @JsonKey(
    
    name: r'phone_people',
    required: true,
    includeIfNull: false,
  )


  final int phonePeople;



  @JsonKey(
    
    name: r'phones_paired',
    required: true,
    includeIfNull: false,
  )


  final int phonesPaired;



  @JsonKey(
    
    name: r'phones_with_sites',
    required: true,
    includeIfNull: false,
  )


  final int phonesWithSites;



      /// Steps on a phone that were asked and denied, handed over or refused
  @JsonKey(
    
    name: r'refused_steps',
    required: true,
    includeIfNull: false,
  )


  final int refusedSteps;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppBrowserNumbers &&
      other.days == days &&
      other.blockedRuns == blockedRuns &&
      other.blockedPeople == blockedPeople &&
      other.watchedBrowserRuns == watchedBrowserRuns &&
      other.phoneRuns == phoneRuns &&
      other.phonePeople == phonePeople &&
      other.phonesPaired == phonesPaired &&
      other.phonesWithSites == phonesWithSites &&
      other.refusedSteps == refusedSteps;

    @override
    int get hashCode =>
        days.hashCode +
        blockedRuns.hashCode +
        blockedPeople.hashCode +
        watchedBrowserRuns.hashCode +
        phoneRuns.hashCode +
        phonePeople.hashCode +
        phonesPaired.hashCode +
        phonesWithSites.hashCode +
        refusedSteps.hashCode;

  factory AppBrowserNumbers.fromJson(Map<String, dynamic> json) => _$AppBrowserNumbersFromJson(json);

  Map<String, dynamic> toJson() => _$AppBrowserNumbersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

