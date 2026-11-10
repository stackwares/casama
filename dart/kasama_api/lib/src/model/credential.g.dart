// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CredentialCWProxy {
  Credential id(String id);

  Credential orgId(String orgId);

  Credential provider(ProviderId provider);

  Credential label(String label);

  Credential baseUrl(String? baseUrl);

  Credential keyHint(String? keyHint);

  Credential lastTestedAt(DateTime? lastTestedAt);

  Credential lastTestOk(bool? lastTestOk);

  Credential ownerUserId(String? ownerUserId);

  Credential status(CredentialStatus status);

  Credential account(String? account);

  Credential fallbackOnLimit(bool fallbackOnLimit);

  Credential createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Credential(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Credential(...).copyWith(id: 12, name: "My name")
  /// ```
  Credential call({
    String id,
    String orgId,
    ProviderId provider,
    String label,
    String? baseUrl,
    String? keyHint,
    DateTime? lastTestedAt,
    bool? lastTestOk,
    String? ownerUserId,
    CredentialStatus status,
    String? account,
    bool fallbackOnLimit,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCredential.copyWith(...)` or call `instanceOfCredential.copyWith.fieldName(value)` for a single field.
class _$CredentialCWProxyImpl implements _$CredentialCWProxy {
  const _$CredentialCWProxyImpl(this._value);

  final Credential _value;

  @override
  Credential id(String id) => call(id: id);

  @override
  Credential orgId(String orgId) => call(orgId: orgId);

  @override
  Credential provider(ProviderId provider) => call(provider: provider);

  @override
  Credential label(String label) => call(label: label);

  @override
  Credential baseUrl(String? baseUrl) => call(baseUrl: baseUrl);

  @override
  Credential keyHint(String? keyHint) => call(keyHint: keyHint);

  @override
  Credential lastTestedAt(DateTime? lastTestedAt) =>
      call(lastTestedAt: lastTestedAt);

  @override
  Credential lastTestOk(bool? lastTestOk) => call(lastTestOk: lastTestOk);

  @override
  Credential ownerUserId(String? ownerUserId) => call(ownerUserId: ownerUserId);

  @override
  Credential status(CredentialStatus status) => call(status: status);

  @override
  Credential account(String? account) => call(account: account);

  @override
  Credential fallbackOnLimit(bool fallbackOnLimit) =>
      call(fallbackOnLimit: fallbackOnLimit);

  @override
  Credential createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Credential(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Credential(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Credential call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? baseUrl = const $CopyWithPlaceholder(),
    Object? keyHint = const $CopyWithPlaceholder(),
    Object? lastTestedAt = const $CopyWithPlaceholder(),
    Object? lastTestOk = const $CopyWithPlaceholder(),
    Object? ownerUserId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? account = const $CopyWithPlaceholder(),
    Object? fallbackOnLimit = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Credential(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as ProviderId,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      baseUrl: baseUrl == const $CopyWithPlaceholder()
          ? _value.baseUrl
          // ignore: cast_nullable_to_non_nullable
          : baseUrl as String?,
      keyHint: keyHint == const $CopyWithPlaceholder()
          ? _value.keyHint
          // ignore: cast_nullable_to_non_nullable
          : keyHint as String?,
      lastTestedAt: lastTestedAt == const $CopyWithPlaceholder()
          ? _value.lastTestedAt
          // ignore: cast_nullable_to_non_nullable
          : lastTestedAt as DateTime?,
      lastTestOk: lastTestOk == const $CopyWithPlaceholder()
          ? _value.lastTestOk
          // ignore: cast_nullable_to_non_nullable
          : lastTestOk as bool?,
      ownerUserId: ownerUserId == const $CopyWithPlaceholder()
          ? _value.ownerUserId
          // ignore: cast_nullable_to_non_nullable
          : ownerUserId as String?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CredentialStatus,
      account: account == const $CopyWithPlaceholder()
          ? _value.account
          // ignore: cast_nullable_to_non_nullable
          : account as String?,
      fallbackOnLimit:
          fallbackOnLimit == const $CopyWithPlaceholder() ||
              fallbackOnLimit == null
          ? _value.fallbackOnLimit
          // ignore: cast_nullable_to_non_nullable
          : fallbackOnLimit as bool,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CredentialCopyWith on Credential {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCredential.copyWith(...)` or `instanceOfCredential.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CredentialCWProxy get copyWith => _$CredentialCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Credential _$CredentialFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Credential',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'provider',
        'label',
        'base_url',
        'key_hint',
        'last_tested_at',
        'last_test_ok',
        'owner_user_id',
        'status',
        'account',
        'fallback_on_limit',
        'created_at',
      ],
    );
    final val = Credential(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      provider: $checkedConvert(
        'provider',
        (v) => $enumDecode(_$ProviderIdEnumMap, v),
      ),
      label: $checkedConvert('label', (v) => v as String),
      baseUrl: $checkedConvert('base_url', (v) => v as String?),
      keyHint: $checkedConvert('key_hint', (v) => v as String?),
      lastTestedAt: $checkedConvert(
        'last_tested_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastTestOk: $checkedConvert('last_test_ok', (v) => v as bool?),
      ownerUserId: $checkedConvert('owner_user_id', (v) => v as String?),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$CredentialStatusEnumMap, v),
      ),
      account: $checkedConvert('account', (v) => v as String?),
      fallbackOnLimit: $checkedConvert('fallback_on_limit', (v) => v as bool),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'baseUrl': 'base_url',
    'keyHint': 'key_hint',
    'lastTestedAt': 'last_tested_at',
    'lastTestOk': 'last_test_ok',
    'ownerUserId': 'owner_user_id',
    'fallbackOnLimit': 'fallback_on_limit',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$CredentialToJson(Credential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'provider': _$ProviderIdEnumMap[instance.provider]!,
      'label': instance.label,
      'base_url': instance.baseUrl,
      'key_hint': instance.keyHint,
      'last_tested_at': instance.lastTestedAt?.toIso8601String(),
      'last_test_ok': instance.lastTestOk,
      'owner_user_id': instance.ownerUserId,
      'status': _$CredentialStatusEnumMap[instance.status]!,
      'account': instance.account,
      'fallback_on_limit': instance.fallbackOnLimit,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ProviderIdEnumMap = {
  ProviderId.openai: 'openai',
  ProviderId.anthropic: 'anthropic',
  ProviderId.google: 'google',
  ProviderId.xai: 'xai',
  ProviderId.openrouter: 'openrouter',
  ProviderId.openaiCompatible: 'openai_compatible',
  ProviderId.fal: 'fal',
  ProviderId.braveSearch: 'brave_search',
  ProviderId.tavily: 'tavily',
  ProviderId.deepgram: 'deepgram',
  ProviderId.elevenlabs: 'elevenlabs',
  ProviderId.cartesia: 'cartesia',
  ProviderId.fishAudio: 'fish_audio',
  ProviderId.chatgpt: 'chatgpt',
  ProviderId.treg: 'treg',
};

const _$CredentialStatusEnumMap = {
  CredentialStatus.ok: 'ok',
  CredentialStatus.planUsageOff: 'plan_usage_off',
  CredentialStatus.needsReconnect: 'needs_reconnect',
};
