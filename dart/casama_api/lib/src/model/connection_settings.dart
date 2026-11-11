//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connection_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectionSettings {
  /// Returns a new [ConnectionSettings] instance.
  ConnectionSettings({

    required  this.composio,

    required  this.composioKey,
  });

      /// server: through this server's Composio account (one click). own: people use their own Composio, Pipedream or Zapier accounts.
  @JsonKey(
    
    name: r'composio',
    required: true,
    includeIfNull: false,
  )


  final ConnectionSettingsComposioEnum composio;



      /// Whether this server has a Composio key (COMPOSIO_API_KEY).
  @JsonKey(
    
    name: r'composio_key',
    required: true,
    includeIfNull: false,
  )


  final bool composioKey;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectionSettings &&
      other.composio == composio &&
      other.composioKey == composioKey;

    @override
    int get hashCode =>
        composio.hashCode +
        composioKey.hashCode;

  factory ConnectionSettings.fromJson(Map<String, dynamic> json) => _$ConnectionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// server: through this server's Composio account (one click). own: people use their own Composio, Pipedream or Zapier accounts.
enum ConnectionSettingsComposioEnum {
    /// server: through this server's Composio account (one click). own: people use their own Composio, Pipedream or Zapier accounts.
@JsonValue(r'server')
server(r'server'),
    /// server: through this server's Composio account (one click). own: people use their own Composio, Pipedream or Zapier accounts.
@JsonValue(r'own')
own(r'own');

const ConnectionSettingsComposioEnum(this.value);

final String value;

@override
String toString() => value;
}


