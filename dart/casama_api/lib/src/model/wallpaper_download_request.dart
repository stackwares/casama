//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallpaper_download_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WallpaperDownloadRequest {
  /// Returns a new [WallpaperDownloadRequest] instance.
  WallpaperDownloadRequest({

    required  this.downloadLocation,
  });

  @JsonKey(
    
    name: r'download_location',
    required: true,
    includeIfNull: false,
  )


  final String downloadLocation;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WallpaperDownloadRequest &&
      other.downloadLocation == downloadLocation;

    @override
    int get hashCode =>
        downloadLocation.hashCode;

  factory WallpaperDownloadRequest.fromJson(Map<String, dynamic> json) => _$WallpaperDownloadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WallpaperDownloadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

