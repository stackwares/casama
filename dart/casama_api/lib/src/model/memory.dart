//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Memory {
  /// Returns a new [Memory] instance.
  Memory({

    required  this.id,

    required  this.kind,

    required  this.content,

    required  this.importance,

    required  this.pinned,

    required  this.createdAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final MemoryKindEnum kind;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;



  @JsonKey(
    
    name: r'importance',
    required: true,
    includeIfNull: false,
  )


  final num importance;



  @JsonKey(
    
    name: r'pinned',
    required: true,
    includeIfNull: false,
  )


  final bool pinned;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Memory &&
      other.id == id &&
      other.kind == kind &&
      other.content == content &&
      other.importance == importance &&
      other.pinned == pinned &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        content.hashCode +
        importance.hashCode +
        pinned.hashCode +
        createdAt.hashCode +
        updatedAt.hashCode;

  factory Memory.fromJson(Map<String, dynamic> json) => _$MemoryFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MemoryKindEnum {
@JsonValue(r'fact')
fact(r'fact'),
@JsonValue(r'episode')
episode(r'episode'),
@JsonValue(r'summary')
summary(r'summary'),
@JsonValue(r'preference')
preference(r'preference');

const MemoryKindEnum(this.value);

final String value;

@override
String toString() => value;
}


