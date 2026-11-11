//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_connection_settings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetConnectionSettingsRequest {
  /// Returns a new [SetConnectionSettingsRequest] instance.
  SetConnectionSettingsRequest({

    required  this.composio,
  });

  @JsonKey(
    
    name: r'composio',
    required: true,
    includeIfNull: false,
  )


  final SetConnectionSettingsRequestComposioEnum composio;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetConnectionSettingsRequest &&
      other.composio == composio;

    @override
    int get hashCode =>
        composio.hashCode;

  factory SetConnectionSettingsRequest.fromJson(Map<String, dynamic> json) => _$SetConnectionSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetConnectionSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetConnectionSettingsRequestComposioEnum {
@JsonValue(r'server')
server(r'server'),
@JsonValue(r'own')
own(r'own');

const SetConnectionSettingsRequestComposioEnum(this.value);

final String value;

@override
String toString() => value;
}


