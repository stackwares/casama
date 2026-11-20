//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/bot_picture_style.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generate_bot_pictures_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GenerateBotPicturesRequest {
  /// Returns a new [GenerateBotPicturesRequest] instance.
  GenerateBotPicturesRequest({

    required  this.style,

     this.description,

     this.count,
  });

  @JsonKey(
    
    name: r'style',
    required: true,
    includeIfNull: false,
  )


  final BotPictureStyle style;



      /// What to draw; empty: Casama works it out from the bot's name and instructions
  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



          // minimum: 1
          // maximum: 2
  @JsonKey(
    
    name: r'count',
    required: false,
    includeIfNull: false,
  )


  final int? count;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GenerateBotPicturesRequest &&
      other.style == style &&
      other.description == description &&
      other.count == count;

    @override
    int get hashCode =>
        style.hashCode +
        description.hashCode +
        count.hashCode;

  factory GenerateBotPicturesRequest.fromJson(Map<String, dynamic> json) => _$GenerateBotPicturesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateBotPicturesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

