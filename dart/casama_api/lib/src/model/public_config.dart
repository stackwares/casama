//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicConfig {
  /// Returns a new [PublicConfig] instance.
  PublicConfig({

    required  this.productName,

    required  this.apiVersion,

    required  this.supabaseUrl,

    required  this.supabaseAnonKey,

    required  this.billingEnabled,

    required  this.defaultModels,

    required  this.defaultReasoningEffort,

     this.wallpapersEnabled,

     this.chatgptSignIn,

     this.signupProofs,

     this.traceUrlTemplate,

     this.googleClientIds,
  });

  @JsonKey(
    
    name: r'product_name',
    required: true,
    includeIfNull: false,
  )


  final String productName;



  @JsonKey(
    
    name: r'api_version',
    required: true,
    includeIfNull: false,
  )


  final String apiVersion;



  @JsonKey(
    
    name: r'supabase_url',
    required: true,
    includeIfNull: false,
  )


  final String supabaseUrl;



  @JsonKey(
    
    name: r'supabase_anon_key',
    required: true,
    includeIfNull: false,
  )


  final String supabaseAnonKey;



  @JsonKey(
    
    name: r'billing_enabled',
    required: true,
    includeIfNull: false,
  )


  final bool billingEnabled;



      /// Default model id per provider (for example openrouter, openai)
  @JsonKey(
    
    name: r'default_models',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> defaultModels;



  @JsonKey(
    
    name: r'default_reasoning_effort',
    required: true,
    includeIfNull: false,
  )


  final PublicConfigDefaultReasoningEffortEnum defaultReasoningEffort;



  @JsonKey(
    
    name: r'wallpapers_enabled',
    required: false,
    includeIfNull: false,
  )


  final bool? wallpapersEnabled;



  @JsonKey(
    
    name: r'chatgpt_sign_in',
    required: false,
    includeIfNull: false,
  )


  final bool? chatgptSignIn;



  @JsonKey(
    
    name: r'signup_proofs',
    required: false,
    includeIfNull: false,
  )


  final List<PublicConfigSignupProofsEnum>? signupProofs;



  @JsonKey(
    
    name: r'trace_url_template',
    required: false,
    includeIfNull: false,
  )


  final String? traceUrlTemplate;



  @JsonKey(
    
    name: r'google_client_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? googleClientIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicConfig &&
      other.productName == productName &&
      other.apiVersion == apiVersion &&
      other.supabaseUrl == supabaseUrl &&
      other.supabaseAnonKey == supabaseAnonKey &&
      other.billingEnabled == billingEnabled &&
      other.defaultModels == defaultModels &&
      other.defaultReasoningEffort == defaultReasoningEffort &&
      other.wallpapersEnabled == wallpapersEnabled &&
      other.chatgptSignIn == chatgptSignIn &&
      other.signupProofs == signupProofs &&
      other.traceUrlTemplate == traceUrlTemplate &&
      other.googleClientIds == googleClientIds;

    @override
    int get hashCode =>
        productName.hashCode +
        apiVersion.hashCode +
        supabaseUrl.hashCode +
        supabaseAnonKey.hashCode +
        billingEnabled.hashCode +
        defaultModels.hashCode +
        defaultReasoningEffort.hashCode +
        wallpapersEnabled.hashCode +
        chatgptSignIn.hashCode +
        signupProofs.hashCode +
        (traceUrlTemplate == null ? 0 : traceUrlTemplate.hashCode) +
        googleClientIds.hashCode;

  factory PublicConfig.fromJson(Map<String, dynamic> json) => _$PublicConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PublicConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PublicConfigDefaultReasoningEffortEnum {
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high'),
@JsonValue(r'xhigh')
xhigh(r'xhigh'),
@JsonValue(r'max')
max(r'max');

const PublicConfigDefaultReasoningEffortEnum(this.value);

final String value;

@override
String toString() => value;
}



enum PublicConfigSignupProofsEnum {
@JsonValue(r'app_check')
appCheck(r'app_check'),
@JsonValue(r'pow')
pow(r'pow');

const PublicConfigSignupProofsEnum(this.value);

final String value;

@override
String toString() => value;
}


