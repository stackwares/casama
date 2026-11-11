//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/computer_size.dart';
import 'package:casama_api/src/model/computer_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Computer {
  /// Returns a new [Computer] instance.
  Computer({

    required  this.id,

    required  this.orgId,

    required  this.kind,

    required  this.name,

    required  this.ownerBotId,

    required  this.provider,

    required  this.profile,

    required  this.state,

    required  this.size,

    required  this.hasSnapshot,

    required  this.maxDesktops,

    required  this.lastActiveAt,

    required  this.error,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ComputerKindEnum kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'owner_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? ownerBotId;



  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final String provider;



  @JsonKey(
    
    name: r'profile',
    required: true,
    includeIfNull: false,
  )


  final ComputerProfileEnum profile;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final ComputerState state;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final ComputerSize size;



  @JsonKey(
    
    name: r'has_snapshot',
    required: true,
    includeIfNull: false,
  )


  final bool hasSnapshot;



      /// Team computers: bots that may use the desktop at the same time
  @JsonKey(
    
    name: r'max_desktops',
    required: true,
    includeIfNull: false,
  )


  final int maxDesktops;



  @JsonKey(
    
    name: r'last_active_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastActiveAt;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Computer &&
      other.id == id &&
      other.orgId == orgId &&
      other.kind == kind &&
      other.name == name &&
      other.ownerBotId == ownerBotId &&
      other.provider == provider &&
      other.profile == profile &&
      other.state == state &&
      other.size == size &&
      other.hasSnapshot == hasSnapshot &&
      other.maxDesktops == maxDesktops &&
      other.lastActiveAt == lastActiveAt &&
      other.error == error &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        kind.hashCode +
        name.hashCode +
        (ownerBotId == null ? 0 : ownerBotId.hashCode) +
        provider.hashCode +
        profile.hashCode +
        state.hashCode +
        size.hashCode +
        hasSnapshot.hashCode +
        maxDesktops.hashCode +
        (lastActiveAt == null ? 0 : lastActiveAt.hashCode) +
        (error == null ? 0 : error.hashCode) +
        createdAt.hashCode;

  factory Computer.fromJson(Map<String, dynamic> json) => _$ComputerFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ComputerKindEnum {
@JsonValue(r'private')
private(r'private'),
@JsonValue(r'team')
team(r'team'),
@JsonValue(r'local')
local(r'local');

const ComputerKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum ComputerProfileEnum {
@JsonValue(r'headless')
headless(r'headless'),
@JsonValue(r'desktop')
desktop(r'desktop');

const ComputerProfileEnum(this.value);

final String value;

@override
String toString() => value;
}


