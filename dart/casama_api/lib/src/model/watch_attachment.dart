//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_attachment.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchAttachment {
  /// Returns a new [WatchAttachment] instance.
  WatchAttachment({

    required  this.kind,

    required  this.title,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final WatchAttachmentKindEnum kind;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchAttachment &&
      other.kind == kind &&
      other.title == title;

    @override
    int get hashCode =>
        kind.hashCode +
        title.hashCode;

  factory WatchAttachment.fromJson(Map<String, dynamic> json) => _$WatchAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$WatchAttachmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchAttachmentKindEnum {
@JsonValue(r'page')
page(r'page'),
@JsonValue(r'image')
image(r'image'),
@JsonValue(r'video')
video(r'video'),
@JsonValue(r'audio')
audio(r'audio'),
@JsonValue(r'document')
document(r'document'),
@JsonValue(r'file')
file(r'file'),
@JsonValue(r'card')
card(r'card'),
@JsonValue(r'link')
link(r'link');

const WatchAttachmentKindEnum(this.value);

final String value;

@override
String toString() => value;
}


