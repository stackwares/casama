//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'take_down_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeDownRequest {
  /// Returns a new [TakeDownRequest] instance.
  TakeDownRequest({

    required  this.down,
  });

  @JsonKey(
    
    name: r'down',
    required: true,
    includeIfNull: false,
  )


  final bool down;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeDownRequest &&
      other.down == down;

    @override
    int get hashCode =>
        down.hashCode;

  factory TakeDownRequest.fromJson(Map<String, dynamic> json) => _$TakeDownRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TakeDownRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

