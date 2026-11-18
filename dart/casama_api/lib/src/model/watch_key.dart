//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_platform.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchKey {
  /// Returns a new [WatchKey] instance.
  WatchKey({

    required  this.id,

    required  this.orgId,

    required  this.platform,

    required  this.name,

    required  this.model,

    required  this.appVersion,

    required  this.osVersion,

    required  this.pairedBy,

    required  this.hasPush,

    required  this.lastUsedAt,

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
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final WatchPlatform platform;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: true,
  )


  final String? model;



  @JsonKey(
    
    name: r'app_version',
    required: true,
    includeIfNull: true,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'os_version',
    required: true,
    includeIfNull: true,
  )


  final String? osVersion;



  @JsonKey(
    
    name: r'paired_by',
    required: true,
    includeIfNull: false,
  )


  final WatchKeyPairedByEnum pairedBy;



  @JsonKey(
    
    name: r'has_push',
    required: true,
    includeIfNull: false,
  )


  final bool hasPush;



  @JsonKey(
    
    name: r'last_used_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastUsedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchKey &&
      other.id == id &&
      other.orgId == orgId &&
      other.platform == platform &&
      other.name == name &&
      other.model == model &&
      other.appVersion == appVersion &&
      other.osVersion == osVersion &&
      other.pairedBy == pairedBy &&
      other.hasPush == hasPush &&
      other.lastUsedAt == lastUsedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        platform.hashCode +
        name.hashCode +
        (model == null ? 0 : model.hashCode) +
        (appVersion == null ? 0 : appVersion.hashCode) +
        (osVersion == null ? 0 : osVersion.hashCode) +
        pairedBy.hashCode +
        hasPush.hashCode +
        (lastUsedAt == null ? 0 : lastUsedAt.hashCode) +
        createdAt.hashCode;

  factory WatchKey.fromJson(Map<String, dynamic> json) => _$WatchKeyFromJson(json);

  Map<String, dynamic> toJson() => _$WatchKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchKeyPairedByEnum {
@JsonValue(r'phone')
phone(r'phone'),
@JsonValue(r'code')
code(r'code');

const WatchKeyPairedByEnum(this.value);

final String value;

@override
String toString() => value;
}


