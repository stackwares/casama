//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_install_result_installed.dart';
import 'package:casama_api/src/model/gallery_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_set_install_result_items_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GallerySetInstallResultItemsInner {
  /// Returns a new [GallerySetInstallResultItemsInner] instance.
  GallerySetInstallResultItemsInner({

    required  this.type,

    required  this.id,

    required  this.status,

    required  this.installed,

    required  this.error,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryKind type;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GallerySetInstallResultItemsInnerStatusEnum status;



  @JsonKey(
    
    name: r'installed',
    required: true,
    includeIfNull: true,
  )


  final GalleryInstallResultInstalled? installed;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GallerySetInstallResultItemsInner &&
      other.type == type &&
      other.id == id &&
      other.status == status &&
      other.installed == installed &&
      other.error == error;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode +
        status.hashCode +
        (installed == null ? 0 : installed.hashCode) +
        (error == null ? 0 : error.hashCode);

  factory GallerySetInstallResultItemsInner.fromJson(Map<String, dynamic> json) => _$GallerySetInstallResultItemsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$GallerySetInstallResultItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GallerySetInstallResultItemsInnerStatusEnum {
@JsonValue(r'installed')
installed(r'installed'),
@JsonValue(r'approval_pending')
approvalPending(r'approval_pending'),
@JsonValue(r'skipped')
skipped(r'skipped'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'device')
device(r'device');

const GallerySetInstallResultItemsInnerStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


