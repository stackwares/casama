//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/paste_import_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'paste_bot_import_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PasteBotImportRequest {
  /// Returns a new [PasteBotImportRequest] instance.
  PasteBotImportRequest({

    required  this.orgId,

    required  this.source_,

    required  this.text,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final PasteImportSource source_;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PasteBotImportRequest &&
      other.orgId == orgId &&
      other.source_ == source_ &&
      other.text == text;

    @override
    int get hashCode =>
        orgId.hashCode +
        source_.hashCode +
        text.hashCode;

  factory PasteBotImportRequest.fromJson(Map<String, dynamic> json) => _$PasteBotImportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PasteBotImportRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

