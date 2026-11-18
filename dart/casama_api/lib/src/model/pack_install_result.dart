//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_install_result_missing.dart';
import 'package:casama_api/src/model/pack_install_item.dart';
import 'package:casama_api/src/model/pack.dart';
import 'package:casama_api/src/model/pack_look_preview.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_install_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackInstallResult {
  /// Returns a new [PackInstallResult] instance.
  PackInstallResult({

    required  this.status,

    required  this.approvalId,

     this.pack,

    required  this.items,

    required  this.missing,

    required  this.looks,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PackInstallResultStatusEnum status;



  @JsonKey(
    
    name: r'approval_id',
    required: true,
    includeIfNull: true,
  )


  final String? approvalId;



  @JsonKey(
    
    name: r'pack',
    required: false,
    includeIfNull: false,
  )


  final Pack? pack;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PackInstallItem> items;



  @JsonKey(
    
    name: r'missing',
    required: true,
    includeIfNull: false,
  )


  final PackInstallResultMissing missing;



      /// Looks to offer on this device
  @JsonKey(
    
    name: r'looks',
    required: true,
    includeIfNull: false,
  )


  final List<PackLookPreview> looks;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackInstallResult &&
      other.status == status &&
      other.approvalId == approvalId &&
      other.pack == pack &&
      other.items == items &&
      other.missing == missing &&
      other.looks == looks;

    @override
    int get hashCode =>
        status.hashCode +
        (approvalId == null ? 0 : approvalId.hashCode) +
        pack.hashCode +
        items.hashCode +
        missing.hashCode +
        looks.hashCode;

  factory PackInstallResult.fromJson(Map<String, dynamic> json) => _$PackInstallResultFromJson(json);

  Map<String, dynamic> toJson() => _$PackInstallResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackInstallResultStatusEnum {
@JsonValue(r'installed')
installed(r'installed'),
@JsonValue(r'approval_pending')
approvalPending(r'approval_pending');

const PackInstallResultStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


