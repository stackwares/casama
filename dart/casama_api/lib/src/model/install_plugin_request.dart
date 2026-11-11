//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'install_plugin_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallPluginRequest {
  /// Returns a new [InstallPluginRequest] instance.
  InstallPluginRequest({

    required  this.orgId,

    required  this.botId,

    required  this.url,

    required  this.commit,

     this.secrets,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;



  @JsonKey(
    
    name: r'secrets',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? secrets;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstallPluginRequest &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.url == url &&
      other.commit == commit &&
      other.secrets == secrets;

    @override
    int get hashCode =>
        orgId.hashCode +
        botId.hashCode +
        url.hashCode +
        commit.hashCode +
        secrets.hashCode;

  factory InstallPluginRequest.fromJson(Map<String, dynamic> json) => _$InstallPluginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InstallPluginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

