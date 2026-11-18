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

     this.composio,

     this.google,
  });

  @JsonKey(
    
    name: r'composio',
    required: false,
    includeIfNull: false,
  )


  final SetConnectionSettingsRequestComposioEnum? composio;



  @JsonKey(
    
    name: r'google',
    required: false,
    includeIfNull: false,
  )


  final SetConnectionSettingsRequestGoogleEnum? google;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetConnectionSettingsRequest &&
      other.composio == composio &&
      other.google == google;

    @override
    int get hashCode =>
        composio.hashCode +
        google.hashCode;

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



enum SetConnectionSettingsRequestGoogleEnum {
@JsonValue(r'composio')
composio(r'composio'),
@JsonValue(r'direct')
direct(r'direct');

const SetConnectionSettingsRequestGoogleEnum(this.value);

final String value;

@override
String toString() => value;
}


