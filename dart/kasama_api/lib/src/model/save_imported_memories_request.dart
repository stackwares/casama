//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/imported_memory_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_imported_memories_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveImportedMemoriesRequest {
  /// Returns a new [SaveImportedMemoriesRequest] instance.
  SaveImportedMemoriesRequest({

    required  this.memories,
  });

  @JsonKey(
    
    name: r'memories',
    required: true,
    includeIfNull: false,
  )


  final List<ImportedMemoryItem> memories;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveImportedMemoriesRequest &&
      other.memories == memories;

    @override
    int get hashCode =>
        memories.hashCode;

  factory SaveImportedMemoriesRequest.fromJson(Map<String, dynamic> json) => _$SaveImportedMemoriesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveImportedMemoriesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

