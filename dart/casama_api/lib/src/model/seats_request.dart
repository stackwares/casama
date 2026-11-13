//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'seats_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SeatsRequest {
  /// Returns a new [SeatsRequest] instance.
  SeatsRequest({

    required  this.extra,
  });

      /// People to pay for beyond the plan's seats
          // minimum: 0
          // maximum: 100
  @JsonKey(
    
    name: r'extra',
    required: true,
    includeIfNull: false,
  )


  final int extra;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SeatsRequest &&
      other.extra == extra;

    @override
    int get hashCode =>
        extra.hashCode;

  factory SeatsRequest.fromJson(Map<String, dynamic> json) => _$SeatsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SeatsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

