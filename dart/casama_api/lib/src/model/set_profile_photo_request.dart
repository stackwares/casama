//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_profile_photo_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetProfilePhotoRequest {
  /// Returns a new [SetProfilePhotoRequest] instance.
  SetProfilePhotoRequest({

    required  this.contentType,

    required  this.data,
  });

  @JsonKey(
    
    name: r'content_type',
    required: true,
    includeIfNull: false,
  )


  final SetProfilePhotoRequestContentTypeEnum contentType;



  @JsonKey(
    
    name: r'data',
    required: true,
    includeIfNull: false,
  )


  final String data;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetProfilePhotoRequest &&
      other.contentType == contentType &&
      other.data == data;

    @override
    int get hashCode =>
        contentType.hashCode +
        data.hashCode;

  factory SetProfilePhotoRequest.fromJson(Map<String, dynamic> json) => _$SetProfilePhotoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetProfilePhotoRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetProfilePhotoRequestContentTypeEnum {
@JsonValue(r'image/jpeg')
imageSlashJpeg(r'image/jpeg'),
@JsonValue(r'image/png')
imageSlashPng(r'image/png'),
@JsonValue(r'image/webp')
imageSlashWebp(r'image/webp');

const SetProfilePhotoRequestContentTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


