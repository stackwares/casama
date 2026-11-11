//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_request_body.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinRequestBody {
  /// Returns a new [JoinRequestBody] instance.
  JoinRequestBody({

    required  this.invite,
  });

      /// An invite link, its token, an email invite token, or a short invite code
  @JsonKey(
    
    name: r'invite',
    required: true,
    includeIfNull: false,
  )


  final String invite;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinRequestBody &&
      other.invite == invite;

    @override
    int get hashCode =>
        invite.hashCode;

  factory JoinRequestBody.fromJson(Map<String, dynamic> json) => _$JoinRequestBodyFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRequestBodyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

