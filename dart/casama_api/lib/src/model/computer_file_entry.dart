//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_file_entry.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerFileEntry {
  /// Returns a new [ComputerFileEntry] instance.
  ComputerFileEntry({

    required  this.name,

    required  this.path,

    required  this.type,

    required  this.size,

    required  this.modified,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final ComputerFileEntryTypeEnum type;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;



  @JsonKey(
    
    name: r'modified',
    required: true,
    includeIfNull: false,
  )


  final String modified;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerFileEntry &&
      other.name == name &&
      other.path == path &&
      other.type == type &&
      other.size == size &&
      other.modified == modified;

    @override
    int get hashCode =>
        name.hashCode +
        path.hashCode +
        type.hashCode +
        size.hashCode +
        modified.hashCode;

  factory ComputerFileEntry.fromJson(Map<String, dynamic> json) => _$ComputerFileEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerFileEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ComputerFileEntryTypeEnum {
@JsonValue(r'file')
file(r'file'),
@JsonValue(r'dir')
dir(r'dir'),
@JsonValue(r'link')
link(r'link');

const ComputerFileEntryTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


