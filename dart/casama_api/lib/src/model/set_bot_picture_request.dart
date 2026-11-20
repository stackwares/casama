//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/bot_picture_crop.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_bot_picture_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetBotPictureRequest {
  /// Returns a new [SetBotPictureRequest] instance.
  SetBotPictureRequest({

    required  this.data,

     this.original,

     this.crop,

     this.source_,
  });

      /// The cropped square (PNG, JPEG or WebP), base64
  @JsonKey(
    
    name: r'data',
    required: true,
    includeIfNull: false,
  )


  final String data;



      /// The picture before cropping, for Re-crop, base64
  @JsonKey(
    
    name: r'original',
    required: false,
    includeIfNull: false,
  )


  final String? original;



  @JsonKey(
    
    name: r'crop',
    required: false,
    includeIfNull: false,
  )


  final BotPictureCrop? crop;



      /// upload (camera, files, paste, drop) or chat (a picture from a conversation)
  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final SetBotPictureRequestSource_Enum? source_;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetBotPictureRequest &&
      other.data == data &&
      other.original == original &&
      other.crop == crop &&
      other.source_ == source_;

    @override
    int get hashCode =>
        data.hashCode +
        original.hashCode +
        crop.hashCode +
        source_.hashCode;

  factory SetBotPictureRequest.fromJson(Map<String, dynamic> json) => _$SetBotPictureRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetBotPictureRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// upload (camera, files, paste, drop) or chat (a picture from a conversation)
enum SetBotPictureRequestSource_Enum {
    /// upload (camera, files, paste, drop) or chat (a picture from a conversation)
@JsonValue(r'upload')
upload(r'upload'),
    /// upload (camera, files, paste, drop) or chat (a picture from a conversation)
@JsonValue(r'chat')
chat(r'chat');

const SetBotPictureRequestSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


