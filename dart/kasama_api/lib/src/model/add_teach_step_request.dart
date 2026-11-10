//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'add_teach_step_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AddTeachStepRequest {
  /// Returns a new [AddTeachStepRequest] instance.
  AddTeachStepRequest({

    required  this.kind,

     this.x,

     this.y,

     this.button,

     this.text,

     this.key,

     this.dx,

     this.dy,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final AddTeachStepRequestKindEnum kind;



          // minimum: 0
          // maximum: 20000
  @JsonKey(
    
    name: r'x',
    required: false,
    includeIfNull: false,
  )


  final int? x;



          // minimum: 0
          // maximum: 20000
  @JsonKey(
    
    name: r'y',
    required: false,
    includeIfNull: false,
  )


  final int? y;



          // minimum: 1
          // maximum: 3
  @JsonKey(
    
    name: r'button',
    required: false,
    includeIfNull: false,
  )


  final int? button;



  @JsonKey(
    
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;



  @JsonKey(
    
    name: r'key',
    required: false,
    includeIfNull: false,
  )


  final String? key;



          // minimum: -10000
          // maximum: 10000
  @JsonKey(
    
    name: r'dx',
    required: false,
    includeIfNull: false,
  )


  final int? dx;



          // minimum: -10000
          // maximum: 10000
  @JsonKey(
    
    name: r'dy',
    required: false,
    includeIfNull: false,
  )


  final int? dy;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AddTeachStepRequest &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.button == button &&
      other.text == text &&
      other.key == key &&
      other.dx == dx &&
      other.dy == dy;

    @override
    int get hashCode =>
        kind.hashCode +
        x.hashCode +
        y.hashCode +
        button.hashCode +
        text.hashCode +
        key.hashCode +
        dx.hashCode +
        dy.hashCode;

  factory AddTeachStepRequest.fromJson(Map<String, dynamic> json) => _$AddTeachStepRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddTeachStepRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AddTeachStepRequestKindEnum {
@JsonValue(r'click')
click(r'click'),
@JsonValue(r'type')
type(r'type'),
@JsonValue(r'key')
key(r'key'),
@JsonValue(r'scroll')
scroll(r'scroll');

const AddTeachStepRequestKindEnum(this.value);

final String value;

@override
String toString() => value;
}


