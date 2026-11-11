//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_mcp_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatedMcpKey {
  /// Returns a new [CreatedMcpKey] instance.
  CreatedMcpKey({

    required  this.id,

    required  this.name,

    required  this.hint,

    required  this.lastUsedAt,

    required  this.createdAt,

    required  this.key,

    required  this.mcpUrl,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'hint',
    required: true,
    includeIfNull: false,
  )


  final String hint;



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



      /// Shown once; paste it into the AI app as a bearer token
  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'mcp_url',
    required: true,
    includeIfNull: false,
  )


  final String mcpUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatedMcpKey &&
      other.id == id &&
      other.name == name &&
      other.hint == hint &&
      other.lastUsedAt == lastUsedAt &&
      other.createdAt == createdAt &&
      other.key == key &&
      other.mcpUrl == mcpUrl;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        hint.hashCode +
        (lastUsedAt == null ? 0 : lastUsedAt.hashCode) +
        createdAt.hashCode +
        key.hashCode +
        mcpUrl.hashCode;

  factory CreatedMcpKey.fromJson(Map<String, dynamic> json) => _$CreatedMcpKeyFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedMcpKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

