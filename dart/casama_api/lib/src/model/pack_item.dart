//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_item_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackItem {
  /// Returns a new [PackItem] instance.
  PackItem({

    required  this.kind,

    required  this.id,

    required  this.name,

    required  this.targetId,

    required  this.botId,

    required  this.edited,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PackItemKind kind;



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
    
    name: r'target_id',
    required: true,
    includeIfNull: true,
  )


  final String? targetId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'edited',
    required: true,
    includeIfNull: false,
  )


  final bool edited;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackItem &&
      other.kind == kind &&
      other.id == id &&
      other.name == name &&
      other.targetId == targetId &&
      other.botId == botId &&
      other.edited == edited;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode +
        name.hashCode +
        (targetId == null ? 0 : targetId.hashCode) +
        (botId == null ? 0 : botId.hashCode) +
        edited.hashCode;

  factory PackItem.fromJson(Map<String, dynamic> json) => _$PackItemFromJson(json);

  Map<String, dynamic> toJson() => _$PackItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

