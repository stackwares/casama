//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'secret_store_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SecretStoreSettings {
  /// Returns a new [SecretStoreSettings] instance.
  SecretStoreSettings({

    required  this.provider,

    required  this.siteUrl,

    required  this.projectId,

    required  this.environment,

    required  this.secretPath,
  });

  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final SecretStoreSettingsProviderEnum provider;



  @JsonKey(
    
    name: r'site_url',
    required: true,
    includeIfNull: true,
  )


  final String? siteUrl;



  @JsonKey(
    
    name: r'project_id',
    required: true,
    includeIfNull: true,
  )


  final String? projectId;



  @JsonKey(
    
    name: r'environment',
    required: true,
    includeIfNull: true,
  )


  final String? environment;



  @JsonKey(
    
    name: r'secret_path',
    required: true,
    includeIfNull: true,
  )


  final String? secretPath;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SecretStoreSettings &&
      other.provider == provider &&
      other.siteUrl == siteUrl &&
      other.projectId == projectId &&
      other.environment == environment &&
      other.secretPath == secretPath;

    @override
    int get hashCode =>
        provider.hashCode +
        (siteUrl == null ? 0 : siteUrl.hashCode) +
        (projectId == null ? 0 : projectId.hashCode) +
        (environment == null ? 0 : environment.hashCode) +
        (secretPath == null ? 0 : secretPath.hashCode);

  factory SecretStoreSettings.fromJson(Map<String, dynamic> json) => _$SecretStoreSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SecretStoreSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SecretStoreSettingsProviderEnum {
@JsonValue(r'vault')
vault(r'vault'),
@JsonValue(r'infisical')
infisical(r'infisical');

const SecretStoreSettingsProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


