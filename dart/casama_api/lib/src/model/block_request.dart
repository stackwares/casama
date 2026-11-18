//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'block_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BlockRequest {
  /// Returns a new [BlockRequest] instance.
  BlockRequest({

    required  this.userId,
  });

  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: false,
  )


  final String userId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BlockRequest &&
      other.userId == userId;

    @override
    int get hashCode =>
        userId.hashCode;

  factory BlockRequest.fromJson(Map<String, dynamic> json) => _$BlockRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BlockRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

