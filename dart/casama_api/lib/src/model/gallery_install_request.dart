//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_workspace_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_install_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInstallRequest {
  /// Returns a new [GalleryInstallRequest] instance.
  GalleryInstallRequest({

    required  this.orgId,

    required  this.type,

    required  this.id,

     this.inputs,

     this.botId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryWorkspaceKind type;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'inputs',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? inputs;



      /// The bot a routine, skill or plugin goes to; a routine needs one
  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryInstallRequest &&
      other.orgId == orgId &&
      other.type == type &&
      other.id == id &&
      other.inputs == inputs &&
      other.botId == botId;

    @override
    int get hashCode =>
        orgId.hashCode +
        type.hashCode +
        id.hashCode +
        inputs.hashCode +
        botId.hashCode;

  factory GalleryInstallRequest.fromJson(Map<String, dynamic> json) => _$GalleryInstallRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInstallRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

