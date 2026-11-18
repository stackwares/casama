//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_install_result_installed.dart';
import 'package:casama_api/src/model/gallery_missing.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_install_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInstallResult {
  /// Returns a new [GalleryInstallResult] instance.
  GalleryInstallResult({

    required  this.status,

    required  this.installed,

    required  this.approvalId,

    required  this.missing,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GalleryInstallResultStatusEnum status;



  @JsonKey(
    
    name: r'installed',
    required: true,
    includeIfNull: true,
  )


  final GalleryInstallResultInstalled? installed;



  @JsonKey(
    
    name: r'approval_id',
    required: true,
    includeIfNull: true,
  )


  final String? approvalId;



  @JsonKey(
    
    name: r'missing',
    required: true,
    includeIfNull: false,
  )


  final GalleryMissing missing;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryInstallResult &&
      other.status == status &&
      other.installed == installed &&
      other.approvalId == approvalId &&
      other.missing == missing;

    @override
    int get hashCode =>
        status.hashCode +
        (installed == null ? 0 : installed.hashCode) +
        (approvalId == null ? 0 : approvalId.hashCode) +
        missing.hashCode;

  factory GalleryInstallResult.fromJson(Map<String, dynamic> json) => _$GalleryInstallResultFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInstallResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryInstallResultStatusEnum {
@JsonValue(r'installed')
installed(r'installed'),
@JsonValue(r'approval_pending')
approvalPending(r'approval_pending');

const GalleryInstallResultStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


