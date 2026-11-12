//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_history_entry.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerHistoryEntry {
  /// Returns a new [ComputerHistoryEntry] instance.
  ComputerHistoryEntry({

    required  this.id,

    required  this.action,

    required  this.actorType,

    required  this.actorId,

    required  this.actorName,

    required  this.metadata,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// computer.started, computer.slept, computer.restarted, computer.reset, computer.erased, checkpoint.created, checkpoint.restored, computer.storage_cleaned, computer.process_stopped, computer.updated
  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final String action;



  @JsonKey(
    
    name: r'actor_type',
    required: true,
    includeIfNull: false,
  )


  final ComputerHistoryEntryActorTypeEnum actorType;



  @JsonKey(
    
    name: r'actor_id',
    required: true,
    includeIfNull: true,
  )


  final String? actorId;



  @JsonKey(
    
    name: r'actor_name',
    required: true,
    includeIfNull: true,
  )


  final String? actorName;



  @JsonKey(
    
    name: r'metadata',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> metadata;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerHistoryEntry &&
      other.id == id &&
      other.action == action &&
      other.actorType == actorType &&
      other.actorId == actorId &&
      other.actorName == actorName &&
      other.metadata == metadata &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        action.hashCode +
        actorType.hashCode +
        (actorId == null ? 0 : actorId.hashCode) +
        (actorName == null ? 0 : actorName.hashCode) +
        metadata.hashCode +
        createdAt.hashCode;

  factory ComputerHistoryEntry.fromJson(Map<String, dynamic> json) => _$ComputerHistoryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerHistoryEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ComputerHistoryEntryActorTypeEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'system')
system(r'system');

const ComputerHistoryEntryActorTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


