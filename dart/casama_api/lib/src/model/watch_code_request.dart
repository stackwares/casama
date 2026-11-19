//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_platform.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_code_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchCodeRequest {
  /// Returns a new [WatchCodeRequest] instance.
  WatchCodeRequest({

    required  this.fingerprint,

    required  this.platform,

    required  this.name,

     this.model,

     this.appVersion,

     this.osVersion,
  });

      /// sha256hex(\"casama-watch-key:\" + key)
  @JsonKey(
    
    name: r'fingerprint',
    required: true,
    includeIfNull: false,
  )


  final String fingerprint;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final WatchPlatform platform;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'model',
    required: false,
    includeIfNull: false,
  )


  final String? model;



  @JsonKey(
    
    name: r'app_version',
    required: false,
    includeIfNull: false,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'os_version',
    required: false,
    includeIfNull: false,
  )


  final String? osVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchCodeRequest &&
      other.fingerprint == fingerprint &&
      other.platform == platform &&
      other.name == name &&
      other.model == model &&
      other.appVersion == appVersion &&
      other.osVersion == osVersion;

    @override
    int get hashCode =>
        fingerprint.hashCode +
        platform.hashCode +
        name.hashCode +
        model.hashCode +
        appVersion.hashCode +
        osVersion.hashCode;

  factory WatchCodeRequest.fromJson(Map<String, dynamic> json) => _$WatchCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WatchCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

