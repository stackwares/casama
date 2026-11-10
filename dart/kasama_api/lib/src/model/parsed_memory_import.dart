//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/imported_memory_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'parsed_memory_import.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ParsedMemoryImport {
  /// Returns a new [ParsedMemoryImport] instance.
  ParsedMemoryImport({

    required  this.memories,
  });

  @JsonKey(
    
    name: r'memories',
    required: true,
    includeIfNull: false,
  )


  final List<ImportedMemoryItem> memories;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ParsedMemoryImport &&
      other.memories == memories;

    @override
    int get hashCode =>
        memories.hashCode;

  factory ParsedMemoryImport.fromJson(Map<String, dynamic> json) => _$ParsedMemoryImportFromJson(json);

  Map<String, dynamic> toJson() => _$ParsedMemoryImportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

