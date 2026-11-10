//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_files_export_files_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceFilesExportFilesInner {
  /// Returns a new [WorkspaceFilesExportFilesInner] instance.
  WorkspaceFilesExportFilesInner({

    required  this.path,

    required  this.contentBase64,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'content_base64',
    required: true,
    includeIfNull: false,
  )


  final String contentBase64;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceFilesExportFilesInner &&
      other.path == path &&
      other.contentBase64 == contentBase64;

    @override
    int get hashCode =>
        path.hashCode +
        contentBase64.hashCode;

  factory WorkspaceFilesExportFilesInner.fromJson(Map<String, dynamic> json) => _$WorkspaceFilesExportFilesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceFilesExportFilesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

