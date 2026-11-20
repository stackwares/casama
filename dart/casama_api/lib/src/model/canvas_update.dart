//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_update.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasUpdate {
  /// Returns a new [CanvasUpdate] instance.
  CanvasUpdate({

     this.status,

     this.hideWhenLocked,
  });

  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  )


  final CanvasUpdateStatusEnum? status;



  @JsonKey(
    
    name: r'hide_when_locked',
    required: false,
    includeIfNull: false,
  )


  final bool? hideWhenLocked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasUpdate &&
      other.status == status &&
      other.hideWhenLocked == hideWhenLocked;

    @override
    int get hashCode =>
        status.hashCode +
        hideWhenLocked.hashCode;

  factory CanvasUpdate.fromJson(Map<String, dynamic> json) => _$CanvasUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasUpdateStatusEnum {
@JsonValue(r'shown')
shown(r'shown'),
@JsonValue(r'paused')
paused(r'paused');

const CanvasUpdateStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


