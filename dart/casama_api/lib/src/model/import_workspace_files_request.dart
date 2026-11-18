//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/start_agent_import_request_files_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'import_workspace_files_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImportWorkspaceFilesRequest {
  /// Returns a new [ImportWorkspaceFilesRequest] instance.
  ImportWorkspaceFilesRequest({

     this.zipBase64,

     this.files,

     this.dryRun,
  });

  @JsonKey(
    
    name: r'zip_base64',
    required: false,
    includeIfNull: false,
  )


  final String? zipBase64;



  @JsonKey(
    
    name: r'files',
    required: false,
    includeIfNull: false,
  )


  final List<StartAgentImportRequestFilesInner>? files;



  @JsonKey(
    
    name: r'dry_run',
    required: false,
    includeIfNull: false,
  )


  final bool? dryRun;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImportWorkspaceFilesRequest &&
      other.zipBase64 == zipBase64 &&
      other.files == files &&
      other.dryRun == dryRun;

    @override
    int get hashCode =>
        zipBase64.hashCode +
        files.hashCode +
        dryRun.hashCode;

  factory ImportWorkspaceFilesRequest.fromJson(Map<String, dynamic> json) => _$ImportWorkspaceFilesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ImportWorkspaceFilesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

