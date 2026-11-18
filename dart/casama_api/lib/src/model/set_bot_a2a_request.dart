//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_bot_a2a_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetBotA2aRequest {
  /// Returns a new [SetBotA2aRequest] instance.
  SetBotA2aRequest({

    required  this.published,
  });

  @JsonKey(
    
    name: r'published',
    required: true,
    includeIfNull: false,
  )


  final bool published;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetBotA2aRequest &&
      other.published == published;

    @override
    int get hashCode =>
        published.hashCode;

  factory SetBotA2aRequest.fromJson(Map<String, dynamic> json) => _$SetBotA2aRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetBotA2aRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

