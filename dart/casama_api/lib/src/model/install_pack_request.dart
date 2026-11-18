//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_item_ref.dart';
import 'package:casama_api/src/model/pack_file_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'install_pack_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallPackRequest {
  /// Returns a new [InstallPackRequest] instance.
  InstallPackRequest({

    required  this.orgId,

     this.url,

     this.commit,

     this.galleryId,

     this.shareToken,

     this.files,

     this.skip,

     this.inputs,

     this.secrets,

     this.settings,

     this.botId,

     this.routinesOn,

     this.deviceId,
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



      /// Items left unticked
  @JsonKey(
    
    name: r'skip',
    required: false,
    includeIfNull: false,
  )


  final List<PackItemRef>? skip;



  @JsonKey(
    
    name: r'inputs',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? inputs;



  @JsonKey(
    
    name: r'secrets',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? secrets;



  @JsonKey(
    
    name: r'settings',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? settings;



      /// Where tools and routines go when the pack brings no bot
  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;



      /// Start the pack's routines switched on (reviewed packs only)
  @JsonKey(
    
    name: r'routines_on',
    required: false,
    includeIfNull: false,
  )


  final bool? routinesOn;



      /// Run the pack's plugin tools (stdio servers) on this paired computer of yours instead of each bot's computer (D-344)
  @JsonKey(
    
    name: r'device_id',
    required: false,
    includeIfNull: false,
  )


  final String? deviceId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstallPackRequest &&
      other.orgId == orgId &&
      other.url == url &&
      other.commit == commit &&
      other.galleryId == galleryId &&
      other.shareToken == shareToken &&
      other.files == files &&
      other.skip == skip &&
      other.inputs == inputs &&
      other.secrets == secrets &&
      other.settings == settings &&
      other.botId == botId &&
      other.routinesOn == routinesOn &&
      other.deviceId == deviceId;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode +
        commit.hashCode +
        galleryId.hashCode +
        shareToken.hashCode +
        files.hashCode +
        skip.hashCode +
        inputs.hashCode +
        secrets.hashCode +
        settings.hashCode +
        botId.hashCode +
        routinesOn.hashCode +
        deviceId.hashCode;

  factory InstallPackRequest.fromJson(Map<String, dynamic> json) => _$InstallPackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InstallPackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

