//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebConfig {
  /// Returns a new [SupportWebConfig] instance.
  SupportWebConfig({

    required  this.assistant,

    required  this.turnstileSiteKey,

    required  this.email,

    required  this.docsUrl,
  });

  @JsonKey(
    
    name: r'assistant',
    required: true,
    includeIfNull: false,
  )


  final bool assistant;



  @JsonKey(
    
    name: r'turnstile_site_key',
    required: true,
    includeIfNull: true,
  )


  final String? turnstileSiteKey;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'docs_url',
    required: true,
    includeIfNull: false,
  )


  final String docsUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebConfig &&
      other.assistant == assistant &&
      other.turnstileSiteKey == turnstileSiteKey &&
      other.email == email &&
      other.docsUrl == docsUrl;

    @override
    int get hashCode =>
        assistant.hashCode +
        (turnstileSiteKey == null ? 0 : turnstileSiteKey.hashCode) +
        email.hashCode +
        docsUrl.hashCode;

  factory SupportWebConfig.fromJson(Map<String, dynamic> json) => _$SupportWebConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

