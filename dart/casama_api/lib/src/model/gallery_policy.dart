//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_policy.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryPolicy {
  /// Returns a new [GalleryPolicy] instance.
  GalleryPolicy({

    required  this.mode,

    required  this.allow,

    required  this.block,

    required  this.approvalFor,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final GalleryPolicyModeEnum mode;



  @JsonKey(
    
    name: r'allow',
    required: true,
    includeIfNull: false,
  )


  final List<String> allow;



  @JsonKey(
    
    name: r'block',
    required: true,
    includeIfNull: false,
  )


  final List<String> block;



  @JsonKey(
    
    name: r'approval_for',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryPolicyApprovalForEnum> approvalFor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryPolicy &&
      other.mode == mode &&
      other.allow == allow &&
      other.block == block &&
      other.approvalFor == approvalFor;

    @override
    int get hashCode =>
        mode.hashCode +
        allow.hashCode +
        block.hashCode +
        approvalFor.hashCode;

  factory GalleryPolicy.fromJson(Map<String, dynamic> json) => _$GalleryPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPolicyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryPolicyModeEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'approval')
approval(r'approval'),
@JsonValue(r'allowlist')
allowlist(r'allowlist');

const GalleryPolicyModeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum GalleryPolicyApprovalForEnum {
@JsonValue(r'runs_code')
runsCode(r'runs_code'),
@JsonValue(r'apps')
apps(r'apps'),
@JsonValue(r'all')
all(r'all');

const GalleryPolicyApprovalForEnum(this.value);

final String value;

@override
String toString() => value;
}


