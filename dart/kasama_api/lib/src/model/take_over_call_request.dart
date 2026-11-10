//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'take_over_call_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeOverCallRequest {
  /// Returns a new [TakeOverCallRequest] instance.
  TakeOverCallRequest({

     this.phone,
  });

  @JsonKey(
    
    name: r'phone',
    required: false,
    includeIfNull: false,
  )


  final String? phone;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeOverCallRequest &&
      other.phone == phone;

    @override
    int get hashCode =>
        phone.hashCode;

  factory TakeOverCallRequest.fromJson(Map<String, dynamic> json) => _$TakeOverCallRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TakeOverCallRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

