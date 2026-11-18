//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_audio.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchAudio {
  /// Returns a new [WatchAudio] instance.
  WatchAudio({

    required  this.data,

    required  this.mime,
  });

  @JsonKey(
    
    name: r'data',
    required: true,
    includeIfNull: false,
  )


  final String data;



  @JsonKey(
    
    name: r'mime',
    required: true,
    includeIfNull: false,
  )


  final WatchAudioMimeEnum mime;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchAudio &&
      other.data == data &&
      other.mime == mime;

    @override
    int get hashCode =>
        data.hashCode +
        mime.hashCode;

  factory WatchAudio.fromJson(Map<String, dynamic> json) => _$WatchAudioFromJson(json);

  Map<String, dynamic> toJson() => _$WatchAudioToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchAudioMimeEnum {
@JsonValue(r'audio/aac')
audioSlashAac(r'audio/aac'),
@JsonValue(r'audio/mp4')
audioSlashMp4(r'audio/mp4'),
@JsonValue(r'audio/m4a')
audioSlashM4a(r'audio/m4a'),
@JsonValue(r'audio/x-m4a')
audioSlashXM4a(r'audio/x-m4a'),
@JsonValue(r'audio/ogg')
audioSlashOgg(r'audio/ogg'),
@JsonValue(r'audio/webm')
audioSlashWebm(r'audio/webm'),
@JsonValue(r'audio/3gpp')
audioSlash3gpp(r'audio/3gpp'),
@JsonValue(r'audio/wav')
audioSlashWav(r'audio/wav');

const WatchAudioMimeEnum(this.value);

final String value;

@override
String toString() => value;
}


