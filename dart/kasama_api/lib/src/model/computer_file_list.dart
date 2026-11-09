//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/computer_file_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_file_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerFileList {
  /// Returns a new [ComputerFileList] instance.
  ComputerFileList({

    required  this.path,

    required  this.entries,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'entries',
    required: true,
    includeIfNull: false,
  )


  final List<ComputerFileEntry> entries;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerFileList &&
      other.path == path &&
      other.entries == entries;

    @override
    int get hashCode =>
        path.hashCode +
        entries.hashCode;

  factory ComputerFileList.fromJson(Map<String, dynamic> json) => _$ComputerFileListFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerFileListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

