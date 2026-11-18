//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_bot_link_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateBotLinkRequest {
  /// Returns a new [CreateBotLinkRequest] instance.
  CreateBotLinkRequest({

    required  this.name,
  });

      /// What you call this contact
  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateBotLinkRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory CreateBotLinkRequest.fromJson(Map<String, dynamic> json) => _$CreateBotLinkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBotLinkRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

