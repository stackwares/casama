//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transcription.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Transcription {
  /// Returns a new [Transcription] instance.
  Transcription({

    required  this.text,

    required  this.provider,

    required  this.seconds,
  });

  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final String provider;



  @JsonKey(
    
    name: r'seconds',
    required: true,
    includeIfNull: false,
  )


  final num seconds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Transcription &&
      other.text == text &&
      other.provider == provider &&
      other.seconds == seconds;

    @override
    int get hashCode =>
        text.hashCode +
        provider.hashCode +
        seconds.hashCode;

  factory Transcription.fromJson(Map<String, dynamic> json) => _$TranscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

