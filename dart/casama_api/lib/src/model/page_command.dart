//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_command.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageCommand {
  /// Returns a new [PageCommand] instance.
  PageCommand({

    required  this.id,

    required  this.name,

    required  this.prompt,

    required  this.position,

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
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'prompt',
    required: true,
    includeIfNull: false,
  )


  final String prompt;



  @JsonKey(
    
    name: r'position',
    required: true,
    includeIfNull: false,
  )


  final int position;



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
    bool operator ==(Object other) => identical(this, other) || other is PageCommand &&
      other.id == id &&
      other.name == name &&
      other.prompt == prompt &&
      other.position == position &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        prompt.hashCode +
        position.hashCode +
        createdAt.hashCode +
        updatedAt.hashCode;

  factory PageCommand.fromJson(Map<String, dynamic> json) => _$PageCommandFromJson(json);

  Map<String, dynamic> toJson() => _$PageCommandToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

