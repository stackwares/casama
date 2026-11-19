//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'waitlist_entry.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WaitlistEntry {
  /// Returns a new [WaitlistEntry] instance.
  WaitlistEntry({

    required  this.id,

    required  this.email,

    required  this.status,

    required  this.source_,

    required  this.ref,

    required  this.selfHosting,

    required  this.note,

    required  this.priority,

    required  this.inviteCode,

    required  this.admittedVia,

    required  this.admittedAt,

    required  this.joinedAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final WaitlistEntryStatusEnum status;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: true,
  )


  final String? source_;



  @JsonKey(
    
    name: r'ref',
    required: true,
    includeIfNull: true,
  )


  final String? ref;



  @JsonKey(
    
    name: r'self_hosting',
    required: true,
    includeIfNull: false,
  )


  final bool selfHosting;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'priority',
    required: true,
    includeIfNull: false,
  )


  final int priority;



  @JsonKey(
    
    name: r'invite_code',
    required: true,
    includeIfNull: true,
  )


  final String? inviteCode;



  @JsonKey(
    
    name: r'admitted_via',
    required: true,
    includeIfNull: true,
  )


  final String? admittedVia;



  @JsonKey(
    
    name: r'admitted_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? admittedAt;



  @JsonKey(
    
    name: r'joined_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? joinedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WaitlistEntry &&
      other.id == id &&
      other.email == email &&
      other.status == status &&
      other.source_ == source_ &&
      other.ref == ref &&
      other.selfHosting == selfHosting &&
      other.note == note &&
      other.priority == priority &&
      other.inviteCode == inviteCode &&
      other.admittedVia == admittedVia &&
      other.admittedAt == admittedAt &&
      other.joinedAt == joinedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        email.hashCode +
        status.hashCode +
        (source_ == null ? 0 : source_.hashCode) +
        (ref == null ? 0 : ref.hashCode) +
        selfHosting.hashCode +
        (note == null ? 0 : note.hashCode) +
        priority.hashCode +
        (inviteCode == null ? 0 : inviteCode.hashCode) +
        (admittedVia == null ? 0 : admittedVia.hashCode) +
        (admittedAt == null ? 0 : admittedAt.hashCode) +
        (joinedAt == null ? 0 : joinedAt.hashCode) +
        createdAt.hashCode;

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) => _$WaitlistEntryFromJson(json);

  Map<String, dynamic> toJson() => _$WaitlistEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WaitlistEntryStatusEnum {
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'queued')
queued(r'queued'),
@JsonValue(r'admitted')
admitted(r'admitted'),
@JsonValue(r'joined')
joined(r'joined');

const WaitlistEntryStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


