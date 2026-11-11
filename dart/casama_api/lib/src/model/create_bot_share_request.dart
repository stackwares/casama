//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_bot_share_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateBotShareRequest {
  /// Returns a new [CreateBotShareRequest] instance.
  CreateBotShareRequest({

     this.includeMemories = false,

     this.expiresInDays = 30,
  });

  @JsonKey(
    defaultValue: false,
    name: r'include_memories',
    required: false,
    includeIfNull: false,
  )


  final bool? includeMemories;



          // minimum: 1
          // maximum: 365
  @JsonKey(
    defaultValue: 30,
    name: r'expires_in_days',
    required: false,
    includeIfNull: false,
  )


  final int? expiresInDays;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateBotShareRequest &&
      other.includeMemories == includeMemories &&
      other.expiresInDays == expiresInDays;

    @override
    int get hashCode =>
        includeMemories.hashCode +
        (expiresInDays == null ? 0 : expiresInDays.hashCode);

  factory CreateBotShareRequest.fromJson(Map<String, dynamic> json) => _$CreateBotShareRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBotShareRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

