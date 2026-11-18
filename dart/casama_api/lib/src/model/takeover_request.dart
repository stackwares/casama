//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'takeover_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeoverRequest {
  /// Returns a new [TakeoverRequest] instance.
  TakeoverRequest({

    required  this.id,

    required  this.botId,

    required  this.runId,

    required  this.computerId,

    required  this.reason,

    required  this.status,

    required  this.note,

    required  this.expiresAt,

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
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final TakeoverRequestStatusEnum status;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeoverRequest &&
      other.id == id &&
      other.botId == botId &&
      other.runId == runId &&
      other.computerId == computerId &&
      other.reason == reason &&
      other.status == status &&
      other.note == note &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        runId.hashCode +
        computerId.hashCode +
        reason.hashCode +
        status.hashCode +
        (note == null ? 0 : note.hashCode) +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory TakeoverRequest.fromJson(Map<String, dynamic> json) => _$TakeoverRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TakeoverRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TakeoverRequestStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'taken')
taken(r'taken'),
@JsonValue(r'completed')
completed(r'completed'),
@JsonValue(r'dismissed')
dismissed(r'dismissed'),
@JsonValue(r'expired')
expired(r'expired');

const TakeoverRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


