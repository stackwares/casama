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

    required  this.google,

    required  this.composioKey,

    required  this.googleDirectAvailable,
  });

      /// server: through this server's Composio account (one click). own: people use their own Composio, Pipedream or Zapier accounts.
  @JsonKey(
    
    name: r'composio',
    required: true,
    includeIfNull: false,
  )


  final ConnectionSettingsComposioEnum composio;



      /// Google's apps. composio: through this server's Composio account whenever it has one (the default; Google's own MCP servers need Developer Preview enrollment, D-166). direct: Google's own MCP servers with GOOGLE_OAUTH_CLIENT_ID. Casama Cloud always uses Composio.
  @JsonKey(
    
    name: r'google',
    required: true,
    includeIfNull: false,
  )


  final ConnectionSettingsGoogleEnum google;



      /// Whether this server has a Composio key (COMPOSIO_API_KEY).
  @JsonKey(
    
    name: r'composio_key',
    required: true,
    includeIfNull: false,
  )


  final bool composioKey;



      /// Whether Google's own servers can be chosen: this server has a Google client (GOOGLE_OAUTH_CLIENT_ID) and isn't Casama Cloud.
  @JsonKey(
    
    name: r'google_direct_available',
    required: true,
    includeIfNull: false,
  )


  final bool googleDirectAvailable;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectionSettings &&
      other.composio == composio &&
      other.google == google &&
      other.composioKey == composioKey &&
      other.googleDirectAvailable == googleDirectAvailable;

    @override
    int get hashCode =>
        composio.hashCode +
        google.hashCode +
        composioKey.hashCode +
        googleDirectAvailable.hashCode;

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


/// Google's apps. composio: through this server's Composio account whenever it has one (the default; Google's own MCP servers need Developer Preview enrollment, D-166). direct: Google's own MCP servers with GOOGLE_OAUTH_CLIENT_ID. Casama Cloud always uses Composio.
enum ConnectionSettingsGoogleEnum {
    /// Google's apps. composio: through this server's Composio account whenever it has one (the default; Google's own MCP servers need Developer Preview enrollment, D-166). direct: Google's own MCP servers with GOOGLE_OAUTH_CLIENT_ID. Casama Cloud always uses Composio.
@JsonValue(r'composio')
composio(r'composio'),
    /// Google's apps. composio: through this server's Composio account whenever it has one (the default; Google's own MCP servers need Developer Preview enrollment, D-166). direct: Google's own MCP servers with GOOGLE_OAUTH_CLIENT_ID. Casama Cloud always uses Composio.
@JsonValue(r'direct')
direct(r'direct');

const ConnectionSettingsGoogleEnum(this.value);

final String value;

@override
String toString() => value;
}


