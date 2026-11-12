//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'remote_app_config_update_urls.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RemoteAppConfigUpdateUrls {
  /// Returns a new [RemoteAppConfigUpdateUrls] instance.
  RemoteAppConfigUpdateUrls({

     this.ios,

     this.android,

     this.macos,

     this.windows,

     this.linux,

     this.web,
  });

  @JsonKey(
    
    name: r'ios',
    required: false,
    includeIfNull: false,
  )


  final String? ios;



  @JsonKey(
    
    name: r'android',
    required: false,
    includeIfNull: false,
  )


  final String? android;



  @JsonKey(
    
    name: r'macos',
    required: false,
    includeIfNull: false,
  )


  final String? macos;



  @JsonKey(
    
    name: r'windows',
    required: false,
    includeIfNull: false,
  )


  final String? windows;



  @JsonKey(
    
    name: r'linux',
    required: false,
    includeIfNull: false,
  )


  final String? linux;



  @JsonKey(
    
    name: r'web',
    required: false,
    includeIfNull: false,
  )


  final String? web;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RemoteAppConfigUpdateUrls &&
      other.ios == ios &&
      other.android == android &&
      other.macos == macos &&
      other.windows == windows &&
      other.linux == linux &&
      other.web == web;

    @override
    int get hashCode =>
        ios.hashCode +
        android.hashCode +
        macos.hashCode +
        windows.hashCode +
        linux.hashCode +
        web.hashCode;

  factory RemoteAppConfigUpdateUrls.fromJson(Map<String, dynamic> json) => _$RemoteAppConfigUpdateUrlsFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteAppConfigUpdateUrlsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

