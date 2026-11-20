//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/bot_picture_crop.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_picture.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotPicture {
  /// Returns a new [BotPicture] instance.
  BotPicture({

    required  this.id,

    required  this.avatarUrl,

    required  this.source_,

    required  this.inUse,

    required  this.hasOriginal,

     this.crop,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// The bots.avatar_url value that uses it
  @JsonKey(
    
    name: r'avatar_url',
    required: true,
    includeIfNull: false,
  )


  final String avatarUrl;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final BotPictureSource_Enum source_;



  @JsonKey(
    
    name: r'in_use',
    required: true,
    includeIfNull: false,
  )


  final bool inUse;



  @JsonKey(
    
    name: r'has_original',
    required: true,
    includeIfNull: false,
  )


  final bool hasOriginal;



  @JsonKey(
    
    name: r'crop',
    required: false,
    includeIfNull: false,
  )


  final BotPictureCrop? crop;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotPicture &&
      other.id == id &&
      other.avatarUrl == avatarUrl &&
      other.source_ == source_ &&
      other.inUse == inUse &&
      other.hasOriginal == hasOriginal &&
      other.crop == crop &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        avatarUrl.hashCode +
        source_.hashCode +
        inUse.hashCode +
        hasOriginal.hashCode +
        crop.hashCode +
        createdAt.hashCode;

  factory BotPicture.fromJson(Map<String, dynamic> json) => _$BotPictureFromJson(json);

  Map<String, dynamic> toJson() => _$BotPictureToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotPictureSource_Enum {
@JsonValue(r'upload')
upload(r'upload'),
@JsonValue(r'chat')
chat(r'chat'),
@JsonValue(r'generated')
generated(r'generated'),
@JsonValue(r'bot')
bot(r'bot');

const BotPictureSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


