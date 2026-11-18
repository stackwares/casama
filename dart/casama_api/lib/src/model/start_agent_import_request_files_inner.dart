//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'start_agent_import_request_files_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StartAgentImportRequestFilesInner {
  /// Returns a new [StartAgentImportRequestFilesInner] instance.
  StartAgentImportRequestFilesInner({

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
    bool operator ==(Object other) => identical(this, other) || other is StartAgentImportRequestFilesInner &&
      other.path == path &&
      other.contentBase64 == contentBase64;

    @override
    int get hashCode =>
        path.hashCode +
        contentBase64.hashCode;

  factory StartAgentImportRequestFilesInner.fromJson(Map<String, dynamic> json) => _$StartAgentImportRequestFilesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$StartAgentImportRequestFilesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

