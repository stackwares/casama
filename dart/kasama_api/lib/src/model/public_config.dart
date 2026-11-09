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





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicConfig &&
      other.productName == productName &&
      other.apiVersion == apiVersion &&
      other.supabaseUrl == supabaseUrl &&
      other.supabaseAnonKey == supabaseAnonKey &&
      other.billingEnabled == billingEnabled;

    @override
    int get hashCode =>
        productName.hashCode +
        apiVersion.hashCode +
        supabaseUrl.hashCode +
        supabaseAnonKey.hashCode +
        billingEnabled.hashCode;

  factory PublicConfig.fromJson(Map<String, dynamic> json) => _$PublicConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PublicConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

