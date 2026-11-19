//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/waitlist_stats_by_source_inner.dart';
import 'package:casama_api/src/model/waitlist_batch.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_stats.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistStats {
  /// Returns a new [WaitlistStats] instance.
  WaitlistStats({

    required  this.waiting,

    required  this.queued,

    required  this.admitted,

    required  this.joined,

    required  this.firstChat,

    required  this.listedToday,

    required  this.admittedToday,

    required  this.emailsToday,

    required  this.bySource,

    required  this.byVia,

     this.lastBatch,
  });

  @JsonKey(
    
    name: r'waiting',
    required: true,
    includeIfNull: false,
  )


  final int waiting;



  @JsonKey(
    
    name: r'queued',
    required: true,
    includeIfNull: false,
  )


  final int queued;



  @JsonKey(
    
    name: r'admitted',
    required: true,
    includeIfNull: false,
  )


  final int admitted;



  @JsonKey(
    
    name: r'joined',
    required: true,
    includeIfNull: false,
  )


  final int joined;



  @JsonKey(
    
    name: r'first_chat',
    required: true,
    includeIfNull: false,
  )


  final int firstChat;



  @JsonKey(
    
    name: r'listed_today',
    required: true,
    includeIfNull: false,
  )


  final int listedToday;



  @JsonKey(
    
    name: r'admitted_today',
    required: true,
    includeIfNull: false,
  )


  final int admittedToday;



  @JsonKey(
    
    name: r'emails_today',
    required: true,
    includeIfNull: false,
  )


  final int emailsToday;



  @JsonKey(
    
    name: r'by_source',
    required: true,
    includeIfNull: false,
  )


  final List<WaitlistStatsBySourceInner> bySource;



  @JsonKey(
    
    name: r'by_via',
    required: true,
    includeIfNull: false,
  )


  final List<WaitlistStatsBySourceInner> byVia;



  @JsonKey(
    
    name: r'last_batch',
    required: false,
    includeIfNull: false,
  )


  final WaitlistBatch? lastBatch;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistStats &&
      other.waiting == waiting &&
      other.queued == queued &&
      other.admitted == admitted &&
      other.joined == joined &&
      other.firstChat == firstChat &&
      other.listedToday == listedToday &&
      other.admittedToday == admittedToday &&
      other.emailsToday == emailsToday &&
      other.bySource == bySource &&
      other.byVia == byVia &&
      other.lastBatch == lastBatch;

    @override
    int get hashCode =>
        waiting.hashCode +
        queued.hashCode +
        admitted.hashCode +
        joined.hashCode +
        firstChat.hashCode +
        listedToday.hashCode +
        admittedToday.hashCode +
        emailsToday.hashCode +
        bySource.hashCode +
        byVia.hashCode +
        (lastBatch == null ? 0 : lastBatch.hashCode);

  factory WaitlistStats.fromJson(Map<String, dynamic> json) => _$WaitlistStatsFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

