//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/announcement.dart';
import 'package:casama_api/src/model/remote_app_config_min_versions.dart';
import 'package:casama_api/src/model/remote_app_config_update_urls.dart';
import 'package:casama_api/src/model/remote_app_config_maintenance.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remote_app_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemoteAppConfig {
  /// Returns a new [RemoteAppConfig] instance.
  RemoteAppConfig({

    required  this.minVersions,

    required  this.updateUrls,

    required  this.maintenance,

    required  this.announcements,

    required  this.flags,
  });

  @JsonKey(
    
    name: r'min_versions',
    required: true,
    includeIfNull: false,
  )


  final RemoteAppConfigMinVersions minVersions;



  @JsonKey(
    
    name: r'update_urls',
    required: true,
    includeIfNull: false,
  )


  final RemoteAppConfigUpdateUrls updateUrls;



  @JsonKey(
    
    name: r'maintenance',
    required: true,
    includeIfNull: true,
  )


  final RemoteAppConfigMaintenance? maintenance;



  @JsonKey(
    
    name: r'announcements',
    required: true,
    includeIfNull: false,
  )


  final List<Announcement> announcements;



      /// Feature switches; a missing name means the app's own default
  @JsonKey(
    
    name: r'flags',
    required: true,
    includeIfNull: false,
  )


  final Map<String, bool> flags;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemoteAppConfig &&
      other.minVersions == minVersions &&
      other.updateUrls == updateUrls &&
      other.maintenance == maintenance &&
      other.announcements == announcements &&
      other.flags == flags;

    @override
    int get hashCode =>
        minVersions.hashCode +
        updateUrls.hashCode +
        (maintenance == null ? 0 : maintenance.hashCode) +
        announcements.hashCode +
        flags.hashCode;

  factory RemoteAppConfig.fromJson(Map<String, dynamic> json) => _$RemoteAppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteAppConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

