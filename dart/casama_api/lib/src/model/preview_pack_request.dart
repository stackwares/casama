//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_file_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'preview_pack_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PreviewPackRequest {
  /// Returns a new [PreviewPackRequest] instance.
  PreviewPackRequest({

    required  this.orgId,

     this.url,

     this.commit,

     this.galleryId,

     this.shareToken,

     this.files,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



      /// A GitHub repository or folder
  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;



  @JsonKey(
    
    name: r'commit',
    required: false,
    includeIfNull: false,
  )


  final String? commit;



      /// A reviewed pack from the plugin directory: installs its reviewed commit
  @JsonKey(
    
    name: r'gallery_id',
    required: false,
    includeIfNull: false,
  )


  final String? galleryId;



      /// A shared pack link
  @JsonKey(
    
    name: r'share_token',
    required: false,
    includeIfNull: false,
  )


  final String? shareToken;



      /// A pack file someone picked (the folder's files)
  @JsonKey(
    
    name: r'files',
    required: false,
    includeIfNull: false,
  )


  final List<PackFileInput>? files;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PreviewPackRequest &&
      other.orgId == orgId &&
      other.url == url &&
      other.commit == commit &&
      other.galleryId == galleryId &&
      other.shareToken == shareToken &&
      other.files == files;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode +
        commit.hashCode +
        galleryId.hashCode +
        shareToken.hashCode +
        files.hashCode;

  factory PreviewPackRequest.fromJson(Map<String, dynamic> json) => _$PreviewPackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PreviewPackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

