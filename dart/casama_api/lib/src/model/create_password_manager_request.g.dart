// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_password_manager_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatePasswordManagerRequestCWProxy {
  CreatePasswordManagerRequest orgId(String orgId);

  CreatePasswordManagerRequest scope(
    CreatePasswordManagerRequestScopeEnum scope,
  );

  CreatePasswordManagerRequest provider(
    CreatePasswordManagerRequestProviderEnum provider,
  );

  CreatePasswordManagerRequest name(String name);

  CreatePasswordManagerRequest url(String url);

  CreatePasswordManagerRequest token(String token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatePasswordManagerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatePasswordManagerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatePasswordManagerRequest call({
    String orgId,
    CreatePasswordManagerRequestScopeEnum scope,
    CreatePasswordManagerRequestProviderEnum provider,
    String name,
    String url,
    String token,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatePasswordManagerRequest.copyWith(...)` or call `instanceOfCreatePasswordManagerRequest.copyWith.fieldName(value)` for a single field.
class _$CreatePasswordManagerRequestCWProxyImpl
    implements _$CreatePasswordManagerRequestCWProxy {
  const _$CreatePasswordManagerRequestCWProxyImpl(this._value);

  final CreatePasswordManagerRequest _value;

  @override
  CreatePasswordManagerRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreatePasswordManagerRequest scope(
    CreatePasswordManagerRequestScopeEnum scope,
  ) => call(scope: scope);

  @override
  CreatePasswordManagerRequest provider(
    CreatePasswordManagerRequestProviderEnum provider,
  ) => call(provider: provider);

  @override
  CreatePasswordManagerRequest name(String name) => call(name: name);

  @override
  CreatePasswordManagerRequest url(String url) => call(url: url);

  @override
  CreatePasswordManagerRequest token(String token) => call(token: token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatePasswordManagerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatePasswordManagerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatePasswordManagerRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? scope = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
  }) {
    return CreatePasswordManagerRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      scope: scope == const $CopyWithPlaceholder() || scope == null
          ? _value.scope
          // ignore: cast_nullable_to_non_nullable
          : scope as CreatePasswordManagerRequestScopeEnum,
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as CreatePasswordManagerRequestProviderEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
    );
  }
}

extension $CreatePasswordManagerRequestCopyWith
    on CreatePasswordManagerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatePasswordManagerRequest.copyWith(...)` or `instanceOfCreatePasswordManagerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatePasswordManagerRequestCWProxy get copyWith =>
      _$CreatePasswordManagerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePasswordManagerRequest _$CreatePasswordManagerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreatePasswordManagerRequest', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['org_id', 'scope', 'provider', 'name', 'url', 'token'],
  );
  final val = CreatePasswordManagerRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    scope: $checkedConvert(
      'scope',
      (v) => $enumDecode(_$CreatePasswordManagerRequestScopeEnumEnumMap, v),
    ),
    provider: $checkedConvert(
      'provider',
      (v) => $enumDecode(_$CreatePasswordManagerRequestProviderEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$CreatePasswordManagerRequestToJson(
  CreatePasswordManagerRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'scope': _$CreatePasswordManagerRequestScopeEnumEnumMap[instance.scope]!,
  'provider':
      _$CreatePasswordManagerRequestProviderEnumEnumMap[instance.provider]!,
  'name': instance.name,
  'url': instance.url,
  'token': instance.token,
};

const _$CreatePasswordManagerRequestScopeEnumEnumMap = {
  CreatePasswordManagerRequestScopeEnum.workspace: 'workspace',
  CreatePasswordManagerRequestScopeEnum.personal: 'personal',
};

const _$CreatePasswordManagerRequestProviderEnumEnumMap = {
  CreatePasswordManagerRequestProviderEnum.n1password: '1password',
  CreatePasswordManagerRequestProviderEnum.bitwarden: 'bitwarden',
};
