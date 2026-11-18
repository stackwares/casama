//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_item_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_install_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackInstallItem {
  /// Returns a new [PackInstallItem] instance.
  PackInstallItem({

    required  this.kind,

    required  this.id,

    required  this.name,

    required  this.status,

    required  this.targetId,

    required  this.error,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PackItemKind kind;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PackInstallItemStatusEnum status;



  @JsonKey(
    
    name: r'target_id',
    required: true,
    includeIfNull: true,
  )


  final String? targetId;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackInstallItem &&
      other.kind == kind &&
      other.id == id &&
      other.name == name &&
      other.status == status &&
      other.targetId == targetId &&
      other.error == error;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode +
        name.hashCode +
        status.hashCode +
        (targetId == null ? 0 : targetId.hashCode) +
        (error == null ? 0 : error.hashCode);

  factory PackInstallItem.fromJson(Map<String, dynamic> json) => _$PackInstallItemFromJson(json);

  Map<String, dynamic> toJson() => _$PackInstallItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackInstallItemStatusEnum {
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

const PackInstallItemStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


