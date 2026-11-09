//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectKey {
  /// Returns a new [ConnectKey] instance.
  ConnectKey({

    required  this.id,

    required  this.instanceName,

    required  this.keyHint,

    required  this.scopes,

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
    
    name: r'instance_name',
    required: true,
    includeIfNull: false,
  )


  final String instanceName;



  @JsonKey(
    
    name: r'key_hint',
    required: true,
    includeIfNull: false,
  )


  final String keyHint;



  @JsonKey(
    
    name: r'scopes',
    required: true,
    includeIfNull: false,
  )


  final List<String> scopes;



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
    bool operator ==(Object other) => identical(this, other) || other is ConnectKey &&
      other.id == id &&
      other.instanceName == instanceName &&
      other.keyHint == keyHint &&
      other.scopes == scopes &&
      other.lastUsedAt == lastUsedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        instanceName.hashCode +
        keyHint.hashCode +
        scopes.hashCode +
        (lastUsedAt == null ? 0 : lastUsedAt.hashCode) +
        createdAt.hashCode;

  factory ConnectKey.fromJson(Map<String, dynamic> json) => _$ConnectKeyFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

