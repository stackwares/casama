//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_starter.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceStarter {
  /// Returns a new [GlanceStarter] instance.
  GlanceStarter({

    required  this.emoji,

    required  this.text,
  });

  @JsonKey(
    
    name: r'emoji',
    required: true,
    includeIfNull: false,
  )


  final String emoji;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceStarter &&
      other.emoji == emoji &&
      other.text == text;

    @override
    int get hashCode =>
        emoji.hashCode +
        text.hashCode;

  factory GlanceStarter.fromJson(Map<String, dynamic> json) => _$GlanceStarterFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceStarterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

