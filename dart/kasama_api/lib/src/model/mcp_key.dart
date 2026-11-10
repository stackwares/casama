//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpKey {
  /// Returns a new [McpKey] instance.
  McpKey({

    required  this.id,

    required  this.name,

    required  this.hint,

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





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpKey &&
      other.id == id &&
      other.name == name &&
      other.hint == hint &&
      other.lastUsedAt == lastUsedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        hint.hashCode +
        (lastUsedAt == null ? 0 : lastUsedAt.hashCode) +
        createdAt.hashCode;

  factory McpKey.fromJson(Map<String, dynamic> json) => _$McpKeyFromJson(json);

  Map<String, dynamic> toJson() => _$McpKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

