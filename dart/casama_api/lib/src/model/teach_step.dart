//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teach_step.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachStep {
  /// Returns a new [TeachStep] instance.
  TeachStep({

    required  this.seq,

    required  this.kind,

    required  this.x,

    required  this.y,

    required  this.button,

    required  this.text,

    required  this.key,

    required  this.dx,

    required  this.dy,

    required  this.secretName,

    required  this.password,

    required  this.url,

    required  this.hasScreenshot,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'seq',
    required: true,
    includeIfNull: false,
  )


  final int seq;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final TeachStepKindEnum kind;



  @JsonKey(
    
    name: r'x',
    required: true,
    includeIfNull: true,
  )


  final int? x;



  @JsonKey(
    
    name: r'y',
    required: true,
    includeIfNull: true,
  )


  final int? y;



  @JsonKey(
    
    name: r'button',
    required: true,
    includeIfNull: true,
  )


  final int? button;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: true,
  )


  final String? text;



  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: true,
  )


  final String? key;



  @JsonKey(
    
    name: r'dx',
    required: true,
    includeIfNull: true,
  )


  final int? dx;



  @JsonKey(
    
    name: r'dy',
    required: true,
    includeIfNull: true,
  )


  final int? dy;



  @JsonKey(
    
    name: r'secret_name',
    required: true,
    includeIfNull: true,
  )


  final String? secretName;



  @JsonKey(
    
    name: r'password',
    required: true,
    includeIfNull: false,
  )


  final bool password;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;



  @JsonKey(
    
    name: r'has_screenshot',
    required: true,
    includeIfNull: false,
  )


  final bool hasScreenshot;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TeachStep &&
      other.seq == seq &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.button == button &&
      other.text == text &&
      other.key == key &&
      other.dx == dx &&
      other.dy == dy &&
      other.secretName == secretName &&
      other.password == password &&
      other.url == url &&
      other.hasScreenshot == hasScreenshot &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        seq.hashCode +
        kind.hashCode +
        (x == null ? 0 : x.hashCode) +
        (y == null ? 0 : y.hashCode) +
        (button == null ? 0 : button.hashCode) +
        (text == null ? 0 : text.hashCode) +
        (key == null ? 0 : key.hashCode) +
        (dx == null ? 0 : dx.hashCode) +
        (dy == null ? 0 : dy.hashCode) +
        (secretName == null ? 0 : secretName.hashCode) +
        password.hashCode +
        (url == null ? 0 : url.hashCode) +
        hasScreenshot.hashCode +
        createdAt.hashCode;

  factory TeachStep.fromJson(Map<String, dynamic> json) => _$TeachStepFromJson(json);

  Map<String, dynamic> toJson() => _$TeachStepToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TeachStepKindEnum {
@JsonValue(r'click')
click(r'click'),
@JsonValue(r'type')
type(r'type'),
@JsonValue(r'key')
key(r'key'),
@JsonValue(r'scroll')
scroll(r'scroll');

const TeachStepKindEnum(this.value);

final String value;

@override
String toString() => value;
}


