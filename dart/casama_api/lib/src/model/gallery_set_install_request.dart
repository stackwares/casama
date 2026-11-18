//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_set_install_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GallerySetInstallRequest {
  /// Returns a new [GallerySetInstallRequest] instance.
  GallerySetInstallRequest({

    required  this.orgId,

     this.botId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



      /// Where the set's routines go
  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GallerySetInstallRequest &&
      other.orgId == orgId &&
      other.botId == botId;

    @override
    int get hashCode =>
        orgId.hashCode +
        botId.hashCode;

  factory GallerySetInstallRequest.fromJson(Map<String, dynamic> json) => _$GallerySetInstallRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GallerySetInstallRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

