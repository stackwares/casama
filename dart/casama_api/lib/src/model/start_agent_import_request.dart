//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/start_agent_import_request_files_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'start_agent_import_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StartAgentImportRequest {
  /// Returns a new [StartAgentImportRequest] instance.
  StartAgentImportRequest({

    required  this.orgId,

     this.zipBase64,

     this.files,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is StartAgentImportRequest &&
      other.orgId == orgId &&
      other.zipBase64 == zipBase64 &&
      other.files == files;

    @override
    int get hashCode =>
        orgId.hashCode +
        zipBase64.hashCode +
        files.hashCode;

  factory StartAgentImportRequest.fromJson(Map<String, dynamic> json) => _$StartAgentImportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartAgentImportRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

