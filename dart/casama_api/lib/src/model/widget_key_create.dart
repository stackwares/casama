//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_key_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WidgetKeyCreate {
  /// Returns a new [WidgetKeyCreate] instance.
  WidgetKeyCreate({

    required  this.orgId,

    required  this.platform,

     this.label,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final WidgetKeyCreatePlatformEnum platform;



  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final String? label;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WidgetKeyCreate &&
      other.orgId == orgId &&
      other.platform == platform &&
      other.label == label;

    @override
    int get hashCode =>
        orgId.hashCode +
        platform.hashCode +
        label.hashCode;

  factory WidgetKeyCreate.fromJson(Map<String, dynamic> json) => _$WidgetKeyCreateFromJson(json);

  Map<String, dynamic> toJson() => _$WidgetKeyCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WidgetKeyCreatePlatformEnum {
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android'),
@JsonValue(r'macos')
macos(r'macos');

const WidgetKeyCreatePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


