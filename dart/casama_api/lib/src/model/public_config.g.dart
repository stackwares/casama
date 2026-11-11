// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicConfigCWProxy {
  PublicConfig productName(String productName);

  PublicConfig apiVersion(String apiVersion);

  PublicConfig supabaseUrl(String supabaseUrl);

  PublicConfig supabaseAnonKey(String supabaseAnonKey);

  PublicConfig billingEnabled(bool billingEnabled);

  PublicConfig defaultModels(Map<String, String> defaultModels);

  PublicConfig defaultReasoningEffort(
    PublicConfigDefaultReasoningEffortEnum defaultReasoningEffort,
  );

  PublicConfig wallpapersEnabled(bool? wallpapersEnabled);

  PublicConfig chatgptSignIn(bool? chatgptSignIn);

  PublicConfig signupProofs(List<PublicConfigSignupProofsEnum>? signupProofs);

  PublicConfig traceUrlTemplate(String? traceUrlTemplate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicConfig call({
    String productName,
    String apiVersion,
    String supabaseUrl,
    String supabaseAnonKey,
    bool billingEnabled,
    Map<String, String> defaultModels,
    PublicConfigDefaultReasoningEffortEnum defaultReasoningEffort,
    bool? wallpapersEnabled,
    bool? chatgptSignIn,
    List<PublicConfigSignupProofsEnum>? signupProofs,
    String? traceUrlTemplate,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicConfig.copyWith(...)` or call `instanceOfPublicConfig.copyWith.fieldName(value)` for a single field.
class _$PublicConfigCWProxyImpl implements _$PublicConfigCWProxy {
  const _$PublicConfigCWProxyImpl(this._value);

  final PublicConfig _value;

  @override
  PublicConfig productName(String productName) =>
      call(productName: productName);

  @override
  PublicConfig apiVersion(String apiVersion) => call(apiVersion: apiVersion);

  @override
  PublicConfig supabaseUrl(String supabaseUrl) =>
      call(supabaseUrl: supabaseUrl);

  @override
  PublicConfig supabaseAnonKey(String supabaseAnonKey) =>
      call(supabaseAnonKey: supabaseAnonKey);

  @override
  PublicConfig billingEnabled(bool billingEnabled) =>
      call(billingEnabled: billingEnabled);

  @override
  PublicConfig defaultModels(Map<String, String> defaultModels) =>
      call(defaultModels: defaultModels);

  @override
  PublicConfig defaultReasoningEffort(
    PublicConfigDefaultReasoningEffortEnum defaultReasoningEffort,
  ) => call(defaultReasoningEffort: defaultReasoningEffort);

  @override
  PublicConfig wallpapersEnabled(bool? wallpapersEnabled) =>
      call(wallpapersEnabled: wallpapersEnabled);

  @override
  PublicConfig chatgptSignIn(bool? chatgptSignIn) =>
      call(chatgptSignIn: chatgptSignIn);

  @override
  PublicConfig signupProofs(List<PublicConfigSignupProofsEnum>? signupProofs) =>
      call(signupProofs: signupProofs);

  @override
  PublicConfig traceUrlTemplate(String? traceUrlTemplate) =>
      call(traceUrlTemplate: traceUrlTemplate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicConfig call({
    Object? productName = const $CopyWithPlaceholder(),
    Object? apiVersion = const $CopyWithPlaceholder(),
    Object? supabaseUrl = const $CopyWithPlaceholder(),
    Object? supabaseAnonKey = const $CopyWithPlaceholder(),
    Object? billingEnabled = const $CopyWithPlaceholder(),
    Object? defaultModels = const $CopyWithPlaceholder(),
    Object? defaultReasoningEffort = const $CopyWithPlaceholder(),
    Object? wallpapersEnabled = const $CopyWithPlaceholder(),
    Object? chatgptSignIn = const $CopyWithPlaceholder(),
    Object? signupProofs = const $CopyWithPlaceholder(),
    Object? traceUrlTemplate = const $CopyWithPlaceholder(),
  }) {
    return PublicConfig(
      productName:
          productName == const $CopyWithPlaceholder() || productName == null
          ? _value.productName
          // ignore: cast_nullable_to_non_nullable
          : productName as String,
      apiVersion:
          apiVersion == const $CopyWithPlaceholder() || apiVersion == null
          ? _value.apiVersion
          // ignore: cast_nullable_to_non_nullable
          : apiVersion as String,
      supabaseUrl:
          supabaseUrl == const $CopyWithPlaceholder() || supabaseUrl == null
          ? _value.supabaseUrl
          // ignore: cast_nullable_to_non_nullable
          : supabaseUrl as String,
      supabaseAnonKey:
          supabaseAnonKey == const $CopyWithPlaceholder() ||
              supabaseAnonKey == null
          ? _value.supabaseAnonKey
          // ignore: cast_nullable_to_non_nullable
          : supabaseAnonKey as String,
      billingEnabled:
          billingEnabled == const $CopyWithPlaceholder() ||
              billingEnabled == null
          ? _value.billingEnabled
          // ignore: cast_nullable_to_non_nullable
          : billingEnabled as bool,
      defaultModels:
          defaultModels == const $CopyWithPlaceholder() || defaultModels == null
          ? _value.defaultModels
          // ignore: cast_nullable_to_non_nullable
          : defaultModels as Map<String, String>,
      defaultReasoningEffort:
          defaultReasoningEffort == const $CopyWithPlaceholder() ||
              defaultReasoningEffort == null
          ? _value.defaultReasoningEffort
          // ignore: cast_nullable_to_non_nullable
          : defaultReasoningEffort as PublicConfigDefaultReasoningEffortEnum,
      wallpapersEnabled: wallpapersEnabled == const $CopyWithPlaceholder()
          ? _value.wallpapersEnabled
          // ignore: cast_nullable_to_non_nullable
          : wallpapersEnabled as bool?,
      chatgptSignIn: chatgptSignIn == const $CopyWithPlaceholder()
          ? _value.chatgptSignIn
          // ignore: cast_nullable_to_non_nullable
          : chatgptSignIn as bool?,
      signupProofs: signupProofs == const $CopyWithPlaceholder()
          ? _value.signupProofs
          // ignore: cast_nullable_to_non_nullable
          : signupProofs as List<PublicConfigSignupProofsEnum>?,
      traceUrlTemplate: traceUrlTemplate == const $CopyWithPlaceholder()
          ? _value.traceUrlTemplate
          // ignore: cast_nullable_to_non_nullable
          : traceUrlTemplate as String?,
    );
  }
}

extension $PublicConfigCopyWith on PublicConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicConfig.copyWith(...)` or `instanceOfPublicConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicConfigCWProxy get copyWith => _$PublicConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicConfig _$PublicConfigFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicConfig',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'product_name',
        'api_version',
        'supabase_url',
        'supabase_anon_key',
        'billing_enabled',
        'default_models',
        'default_reasoning_effort',
      ],
    );
    final val = PublicConfig(
      productName: $checkedConvert('product_name', (v) => v as String),
      apiVersion: $checkedConvert('api_version', (v) => v as String),
      supabaseUrl: $checkedConvert('supabase_url', (v) => v as String),
      supabaseAnonKey: $checkedConvert('supabase_anon_key', (v) => v as String),
      billingEnabled: $checkedConvert('billing_enabled', (v) => v as bool),
      defaultModels: $checkedConvert(
        'default_models',
        (v) => Map<String, String>.from(v as Map),
      ),
      defaultReasoningEffort: $checkedConvert(
        'default_reasoning_effort',
        (v) => $enumDecode(_$PublicConfigDefaultReasoningEffortEnumEnumMap, v),
      ),
      wallpapersEnabled: $checkedConvert(
        'wallpapers_enabled',
        (v) => v as bool?,
      ),
      chatgptSignIn: $checkedConvert('chatgpt_sign_in', (v) => v as bool?),
      signupProofs: $checkedConvert(
        'signup_proofs',
        (v) => (v as List<dynamic>?)
            ?.map((e) => $enumDecode(_$PublicConfigSignupProofsEnumEnumMap, e))
            .toList(),
      ),
      traceUrlTemplate: $checkedConvert(
        'trace_url_template',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'productName': 'product_name',
    'apiVersion': 'api_version',
    'supabaseUrl': 'supabase_url',
    'supabaseAnonKey': 'supabase_anon_key',
    'billingEnabled': 'billing_enabled',
    'defaultModels': 'default_models',
    'defaultReasoningEffort': 'default_reasoning_effort',
    'wallpapersEnabled': 'wallpapers_enabled',
    'chatgptSignIn': 'chatgpt_sign_in',
    'signupProofs': 'signup_proofs',
    'traceUrlTemplate': 'trace_url_template',
  },
);

Map<String, dynamic> _$PublicConfigToJson(PublicConfig instance) =>
    <String, dynamic>{
      'product_name': instance.productName,
      'api_version': instance.apiVersion,
      'supabase_url': instance.supabaseUrl,
      'supabase_anon_key': instance.supabaseAnonKey,
      'billing_enabled': instance.billingEnabled,
      'default_models': instance.defaultModels,
      'default_reasoning_effort':
          _$PublicConfigDefaultReasoningEffortEnumEnumMap[instance
              .defaultReasoningEffort]!,
      'wallpapers_enabled': ?instance.wallpapersEnabled,
      'chatgpt_sign_in': ?instance.chatgptSignIn,
      'signup_proofs': ?instance.signupProofs
          ?.map((e) => _$PublicConfigSignupProofsEnumEnumMap[e]!)
          .toList(),
      'trace_url_template': ?instance.traceUrlTemplate,
    };

const _$PublicConfigDefaultReasoningEffortEnumEnumMap = {
  PublicConfigDefaultReasoningEffortEnum.none: 'none',
  PublicConfigDefaultReasoningEffortEnum.low: 'low',
  PublicConfigDefaultReasoningEffortEnum.medium: 'medium',
  PublicConfigDefaultReasoningEffortEnum.high: 'high',
  PublicConfigDefaultReasoningEffortEnum.xhigh: 'xhigh',
  PublicConfigDefaultReasoningEffortEnum.max: 'max',
};

const _$PublicConfigSignupProofsEnumEnumMap = {
  PublicConfigSignupProofsEnum.appCheck: 'app_check',
  PublicConfigSignupProofsEnum.pow: 'pow',
};
