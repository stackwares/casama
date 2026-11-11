//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_agent_import_files_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteAgentImportFilesResponse {
  /// Returns a new [WriteAgentImportFilesResponse] instance.
  WriteAgentImportFilesResponse({

    required  this.written,

    required  this.folder,
  });

  @JsonKey(
    
    name: r'written',
    required: true,
    includeIfNull: false,
  )


  final int written;



  @JsonKey(
    
    name: r'folder',
    required: true,
    includeIfNull: false,
  )


  final String folder;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WriteAgentImportFilesResponse &&
      other.written == written &&
      other.folder == folder;

    @override
    int get hashCode =>
        written.hashCode +
        folder.hashCode;

  factory WriteAgentImportFilesResponse.fromJson(Map<String, dynamic> json) => _$WriteAgentImportFilesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WriteAgentImportFilesResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

