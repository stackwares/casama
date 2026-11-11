//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/workspace_files_export_files_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_files_export.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceFilesExport {
  /// Returns a new [WorkspaceFilesExport] instance.
  WorkspaceFilesExport({

    required  this.zipBase64,

    required  this.count,

    required  this.files,
  });

  @JsonKey(
    
    name: r'zip_base64',
    required: true,
    includeIfNull: false,
  )


  final String zipBase64;



  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<WorkspaceFilesExportFilesInner> files;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceFilesExport &&
      other.zipBase64 == zipBase64 &&
      other.count == count &&
      other.files == files;

    @override
    int get hashCode =>
        zipBase64.hashCode +
        count.hashCode +
        files.hashCode;

  factory WorkspaceFilesExport.fromJson(Map<String, dynamic> json) => _$WorkspaceFilesExportFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceFilesExportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

