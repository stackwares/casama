//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'limit_reset_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LimitResetEvent {
  /// Returns a new [LimitResetEvent] instance.
  LimitResetEvent({

    required  this.id,

    required  this.campaignId,

    required  this.resetId,

    required  this.orgId,

    required  this.actorId,

    required  this.action,

    required  this.before,

    required  this.after,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'campaign_id',
    required: true,
    includeIfNull: true,
  )


  final String? campaignId;



  @JsonKey(
    
    name: r'reset_id',
    required: true,
    includeIfNull: true,
  )


  final String? resetId;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: true,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'actor_id',
    required: true,
    includeIfNull: true,
  )


  final String? actorId;



  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final String action;



  @JsonKey(
    
    name: r'before',
    required: true,
    includeIfNull: true,
  )


  final Map<String, Object?>? before;



  @JsonKey(
    
    name: r'after',
    required: true,
    includeIfNull: true,
  )


  final Map<String, Object?>? after;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LimitResetEvent &&
      other.id == id &&
      other.campaignId == campaignId &&
      other.resetId == resetId &&
      other.orgId == orgId &&
      other.actorId == actorId &&
      other.action == action &&
      other.before == before &&
      other.after == after &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        (campaignId == null ? 0 : campaignId.hashCode) +
        (resetId == null ? 0 : resetId.hashCode) +
        (orgId == null ? 0 : orgId.hashCode) +
        (actorId == null ? 0 : actorId.hashCode) +
        action.hashCode +
        (before == null ? 0 : before.hashCode) +
        (after == null ? 0 : after.hashCode) +
        createdAt.hashCode;

  factory LimitResetEvent.fromJson(Map<String, dynamic> json) => _$LimitResetEventFromJson(json);

  Map<String, dynamic> toJson() => _$LimitResetEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

