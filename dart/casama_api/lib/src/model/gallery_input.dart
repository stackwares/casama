//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_input.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInput {
  /// Returns a new [GalleryInput] instance.
  GalleryInput({

    required  this.key,

    required  this.label,

    required  this.type,

     this.default_,

     this.options,

     this.help,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryInputTypeEnum type;



  @JsonKey(
    
    name: r'default',
    required: false,
    includeIfNull: false,
  )


  final String? default_;



  @JsonKey(
    
    name: r'options',
    required: false,
    includeIfNull: false,
  )


  final List<String>? options;



  @JsonKey(
    
    name: r'help',
    required: false,
    includeIfNull: false,
  )


  final String? help;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryInput &&
      other.key == key &&
      other.label == label &&
      other.type == type &&
      other.default_ == default_ &&
      other.options == options &&
      other.help == help;

    @override
    int get hashCode =>
        key.hashCode +
        label.hashCode +
        type.hashCode +
        default_.hashCode +
        options.hashCode +
        help.hashCode;

  factory GalleryInput.fromJson(Map<String, dynamic> json) => _$GalleryInputFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryInputTypeEnum {
@JsonValue(r'text')
text(r'text'),
@JsonValue(r'choice')
choice(r'choice'),
@JsonValue(r'time')
time(r'time'),
@JsonValue(r'timezone')
timezone(r'timezone');

const GalleryInputTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


