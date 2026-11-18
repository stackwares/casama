//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'export_pack_request_look.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExportPackRequestLook {
  /// Returns a new [ExportPackRequestLook] instance.
  ExportPackRequestLook({

    required  this.type,

    required  this.name,

    required  this.document,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final ExportPackRequestLookTypeEnum type;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'document',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> document;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ExportPackRequestLook &&
      other.type == type &&
      other.name == name &&
      other.document == document;

    @override
    int get hashCode =>
        type.hashCode +
        name.hashCode +
        document.hashCode;

  factory ExportPackRequestLook.fromJson(Map<String, dynamic> json) => _$ExportPackRequestLookFromJson(json);

  Map<String, dynamic> toJson() => _$ExportPackRequestLookToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ExportPackRequestLookTypeEnum {
@JsonValue(r'theme')
theme(r'theme'),
@JsonValue(r'scheme')
scheme(r'scheme'),
@JsonValue(r'wallpaper')
wallpaper(r'wallpaper');

const ExportPackRequestLookTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


