//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'write_agent_import_files_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WriteAgentImportFilesRequest {
  /// Returns a new [WriteAgentImportFilesRequest] instance.
  WriteAgentImportFilesRequest({

    required  this.botId,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WriteAgentImportFilesRequest &&
      other.botId == botId;

    @override
    int get hashCode =>
        botId.hashCode;

  factory WriteAgentImportFilesRequest.fromJson(Map<String, dynamic> json) => _$WriteAgentImportFilesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WriteAgentImportFilesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

