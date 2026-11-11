//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decide_join_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecideJoinRequest {
  /// Returns a new [DecideJoinRequest] instance.
  DecideJoinRequest({

    required  this.approve,
  });

  @JsonKey(
    
    name: r'approve',
    required: true,
    includeIfNull: false,
  )


  final bool approve;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecideJoinRequest &&
      other.approve == approve;

    @override
    int get hashCode =>
        approve.hashCode;

  factory DecideJoinRequest.fromJson(Map<String, dynamic> json) => _$DecideJoinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DecideJoinRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

