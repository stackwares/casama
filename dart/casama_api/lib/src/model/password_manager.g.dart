// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_manager.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasswordManagerCWProxy {
  PasswordManager id(String id);

  PasswordManager scope(PasswordManagerScopeEnum scope);

  PasswordManager provider(PasswordManagerProviderEnum provider);

  PasswordManager name(String name);

  PasswordManager url(String url);

  PasswordManager allowedVaults(List<String> allowedVaults);

  PasswordManager allowedBotIds(List<String>? allowedBotIds);

  PasswordManager status(PasswordManagerStatusEnum status);

  PasswordManager lastError(String? lastError);

  PasswordManager createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManager(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManager(...).copyWith(id: 12, name: "My name")
  /// ```
  PasswordManager call({
    String id,
    PasswordManagerScopeEnum scope,
    PasswordManagerProviderEnum provider,
    String name,
    String url,
    List<String> allowedVaults,
    List<String>? allowedBotIds,
    PasswordManagerStatusEnum status,
    String? lastError,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPasswordManager.copyWith(...)` or call `instanceOfPasswordManager.copyWith.fieldName(value)` for a single field.
class _$PasswordManagerCWProxyImpl implements _$PasswordManagerCWProxy {
  const _$PasswordManagerCWProxyImpl(this._value);

  final PasswordManager _value;

  @override
  PasswordManager id(String id) => call(id: id);

  @override
  PasswordManager scope(PasswordManagerScopeEnum scope) => call(scope: scope);

  @override
  PasswordManager provider(PasswordManagerProviderEnum provider) =>
      call(provider: provider);

  @override
  PasswordManager name(String name) => call(name: name);

  @override
  PasswordManager url(String url) => call(url: url);

  @override
  PasswordManager allowedVaults(List<String> allowedVaults) =>
      call(allowedVaults: allowedVaults);

  @override
  PasswordManager allowedBotIds(List<String>? allowedBotIds) =>
      call(allowedBotIds: allowedBotIds);

  @override
  PasswordManager status(PasswordManagerStatusEnum status) =>
      call(status: status);

  @override
  PasswordManager lastError(String? lastError) => call(lastError: lastError);

  @override
  PasswordManager createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManager(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManager(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PasswordManager call({
    Object? id = const $CopyWithPlaceholder(),
    Object? scope = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? allowedVaults = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? lastError = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return PasswordManager(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      scope: scope == const $CopyWithPlaceholder() || scope == null
          ? _value.scope
          // ignore: cast_nullable_to_non_nullable
          : scope as PasswordManagerScopeEnum,
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as PasswordManagerProviderEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      allowedVaults:
          allowedVaults == const $CopyWithPlaceholder() || allowedVaults == null
          ? _value.allowedVaults
          // ignore: cast_nullable_to_non_nullable
          : allowedVaults as List<String>,
      allowedBotIds: allowedBotIds == const $CopyWithPlaceholder()
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>?,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PasswordManagerStatusEnum,
      lastError: lastError == const $CopyWithPlaceholder()
          ? _value.lastError
          // ignore: cast_nullable_to_non_nullable
          : lastError as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $PasswordManagerCopyWith on PasswordManager {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPasswordManager.copyWith(...)` or `instanceOfPasswordManager.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasswordManagerCWProxy get copyWith => _$PasswordManagerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordManager _$PasswordManagerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PasswordManager',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'scope',
            'provider',
            'name',
            'url',
            'allowed_vaults',
            'allowed_bot_ids',
            'status',
            'last_error',
            'created_at',
          ],
        );
        final val = PasswordManager(
          id: $checkedConvert('id', (v) => v as String),
          scope: $checkedConvert(
            'scope',
            (v) => $enumDecode(_$PasswordManagerScopeEnumEnumMap, v),
          ),
          provider: $checkedConvert(
            'provider',
            (v) => $enumDecode(_$PasswordManagerProviderEnumEnumMap, v),
          ),
          name: $checkedConvert('name', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          allowedVaults: $checkedConvert(
            'allowed_vaults',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          allowedBotIds: $checkedConvert(
            'allowed_bot_ids',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$PasswordManagerStatusEnumEnumMap, v),
          ),
          lastError: $checkedConvert('last_error', (v) => v as String?),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'allowedVaults': 'allowed_vaults',
        'allowedBotIds': 'allowed_bot_ids',
        'lastError': 'last_error',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$PasswordManagerToJson(PasswordManager instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scope': _$PasswordManagerScopeEnumEnumMap[instance.scope]!,
      'provider': _$PasswordManagerProviderEnumEnumMap[instance.provider]!,
      'name': instance.name,
      'url': instance.url,
      'allowed_vaults': instance.allowedVaults,
      'allowed_bot_ids': instance.allowedBotIds,
      'status': _$PasswordManagerStatusEnumEnumMap[instance.status]!,
      'last_error': instance.lastError,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PasswordManagerScopeEnumEnumMap = {
  PasswordManagerScopeEnum.workspace: 'workspace',
  PasswordManagerScopeEnum.personal: 'personal',
};

const _$PasswordManagerProviderEnumEnumMap = {
  PasswordManagerProviderEnum.n1password: '1password',
  PasswordManagerProviderEnum.bitwarden: 'bitwarden',
};

const _$PasswordManagerStatusEnumEnumMap = {
  PasswordManagerStatusEnum.ok: 'ok',
  PasswordManagerStatusEnum.error: 'error',
};
