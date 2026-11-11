//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_attachment.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageAttachment {
  /// Returns a new [MessageAttachment] instance.
  MessageAttachment({

    required  this.path,

    required  this.name,

    required  this.mimeType,

    required  this.size,
  });

      /// Where the file is on the bot's computer, under its home folder (upload it first)
  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'mime_type',
    required: true,
    includeIfNull: false,
  )


  final String mimeType;



          // minimum: 0
  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageAttachment &&
      other.path == path &&
      other.name == name &&
      other.mimeType == mimeType &&
      other.size == size;

    @override
    int get hashCode =>
        path.hashCode +
        name.hashCode +
        mimeType.hashCode +
        size.hashCode;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => _$MessageAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$MessageAttachmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

