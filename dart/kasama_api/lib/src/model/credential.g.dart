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

  Credential createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Credential(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Credential(...).copyWith(id: 12, name: "My name")
  /// ````
  Credential call({
    String id,
    String orgId,
    ProviderId provider,
    String label,
    String? baseUrl,
    String? keyHint,
    DateTime? lastTestedAt,
    bool? lastTestOk,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCredential.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCredential.copyWith.fieldName(...)`
class _$CredentialCWProxyImpl implements _$CredentialCWProxy {
  const _$CredentialCWProxyImpl(this._value);

  final Credential _value;

  @override
  Credential id(String id) => this(id: id);

  @override
  Credential orgId(String orgId) => this(orgId: orgId);

  @override
  Credential provider(ProviderId provider) => this(provider: provider);

  @override
  Credential label(String label) => this(label: label);

  @override
  Credential baseUrl(String? baseUrl) => this(baseUrl: baseUrl);

  @override
  Credential keyHint(String? keyHint) => this(keyHint: keyHint);

  @override
  Credential lastTestedAt(DateTime? lastTestedAt) =>
      this(lastTestedAt: lastTestedAt);

  @override
  Credential lastTestOk(bool? lastTestOk) => this(lastTestOk: lastTestOk);

  @override
  Credential createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Credential(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Credential(...).copyWith(id: 12, name: "My name")
  /// ````
  Credential call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? baseUrl = const $CopyWithPlaceholder(),
    Object? keyHint = const $CopyWithPlaceholder(),
    Object? lastTestedAt = const $CopyWithPlaceholder(),
    Object? lastTestOk = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Credential(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as ProviderId,
      label: label == const $CopyWithPlaceholder()
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
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CredentialCopyWith on Credential {
  /// Returns a callable class that can be used as follows: `instanceOfCredential.copyWith(...)` or like so:`instanceOfCredential.copyWith.fieldName(...)`.
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
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ProviderIdEnumMap = {
  ProviderId.openai: 'openai',
  ProviderId.anthropic: 'anthropic',
  ProviderId.google: 'google',
  ProviderId.xai: 'xai',
  ProviderId.openrouter: 'openrouter',
  ProviderId.openaiCompatible: 'openai_compatible',
};
