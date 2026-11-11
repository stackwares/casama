//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watcher.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Watcher {
  /// Returns a new [Watcher] instance.
  Watcher({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.kind,

    required  this.target,

    required  this.conditionMd,

    required  this.status,

    required  this.checkEverySeconds,

    required  this.firedCount,

    required  this.lastCheckedAt,

    required  this.lastError,

    required  this.expiresAt,

    required  this.conversationId,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final WatcherKindEnum kind;



  @JsonKey(
    
    name: r'target',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> target;



  @JsonKey(
    
    name: r'condition_md',
    required: true,
    includeIfNull: false,
  )


  final String conditionMd;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final WatcherStatusEnum status;



  @JsonKey(
    
    name: r'check_every_seconds',
    required: true,
    includeIfNull: false,
  )


  final int checkEverySeconds;



  @JsonKey(
    
    name: r'fired_count',
    required: true,
    includeIfNull: false,
  )


  final int firedCount;



  @JsonKey(
    
    name: r'last_checked_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastCheckedAt;



  @JsonKey(
    
    name: r'last_error',
    required: true,
    includeIfNull: true,
  )


  final String? lastError;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Watcher &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.kind == kind &&
      other.target == target &&
      other.conditionMd == conditionMd &&
      other.status == status &&
      other.checkEverySeconds == checkEverySeconds &&
      other.firedCount == firedCount &&
      other.lastCheckedAt == lastCheckedAt &&
      other.lastError == lastError &&
      other.expiresAt == expiresAt &&
      other.conversationId == conversationId &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        kind.hashCode +
        target.hashCode +
        conditionMd.hashCode +
        status.hashCode +
        checkEverySeconds.hashCode +
        firedCount.hashCode +
        (lastCheckedAt == null ? 0 : lastCheckedAt.hashCode) +
        (lastError == null ? 0 : lastError.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        createdAt.hashCode;

  factory Watcher.fromJson(Map<String, dynamic> json) => _$WatcherFromJson(json);

  Map<String, dynamic> toJson() => _$WatcherToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatcherKindEnum {
@JsonValue(r'page_change')
pageChange(r'page_change'),
@JsonValue(r'reply')
reply(r'reply'),
@JsonValue(r'query')
query(r'query'),
@JsonValue(r'time')
time(r'time');

const WatcherKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum WatcherStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'paused')
paused(r'paused'),
@JsonValue(r'done')
done(r'done'),
@JsonValue(r'expired')
expired(r'expired');

const WatcherStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


