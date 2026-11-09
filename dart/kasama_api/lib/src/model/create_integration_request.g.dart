// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_integration_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateIntegrationRequestCWProxy {
  CreateIntegrationRequest orgId(String orgId);

  CreateIntegrationRequest kind(IntegrationKind kind);

  CreateIntegrationRequest name(String name);

  CreateIntegrationRequest config(Map<String, Object?> config);

  CreateIntegrationRequest secret(String? secret);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateIntegrationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateIntegrationRequest call({
    String orgId,
    IntegrationKind kind,
    String name,
    Map<String, Object?> config,
    String? secret,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateIntegrationRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateIntegrationRequest.copyWith.fieldName(...)`
class _$CreateIntegrationRequestCWProxyImpl
    implements _$CreateIntegrationRequestCWProxy {
  const _$CreateIntegrationRequestCWProxyImpl(this._value);

  final CreateIntegrationRequest _value;

  @override
  CreateIntegrationRequest orgId(String orgId) => this(orgId: orgId);

  @override
  CreateIntegrationRequest kind(IntegrationKind kind) => this(kind: kind);

  @override
  CreateIntegrationRequest name(String name) => this(name: name);

  @override
  CreateIntegrationRequest config(Map<String, Object?> config) =>
      this(config: config);

  @override
  CreateIntegrationRequest secret(String? secret) => this(secret: secret);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateIntegrationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateIntegrationRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? config = const $CopyWithPlaceholder(),
    Object? secret = const $CopyWithPlaceholder(),
  }) {
    return CreateIntegrationRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as IntegrationKind,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      config: config == const $CopyWithPlaceholder()
          ? _value.config
          // ignore: cast_nullable_to_non_nullable
          : config as Map<String, Object?>,
      secret: secret == const $CopyWithPlaceholder()
          ? _value.secret
          // ignore: cast_nullable_to_non_nullable
          : secret as String?,
    );
  }
}

extension $CreateIntegrationRequestCopyWith on CreateIntegrationRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateIntegrationRequest.copyWith(...)` or like so:`instanceOfCreateIntegrationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateIntegrationRequestCWProxy get copyWith =>
      _$CreateIntegrationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateIntegrationRequest _$CreateIntegrationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateIntegrationRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'kind', 'name', 'config']);
  final val = CreateIntegrationRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$IntegrationKindEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    config: $checkedConvert('config', (v) => v as Map<String, dynamic>),
    secret: $checkedConvert('secret', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$CreateIntegrationRequestToJson(
  CreateIntegrationRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'kind': _$IntegrationKindEnumMap[instance.kind]!,
  'name': instance.name,
  'config': instance.config,
  'secret': ?instance.secret,
};

const _$IntegrationKindEnumMap = {
  IntegrationKind.mcp: 'mcp',
  IntegrationKind.openapi: 'openapi',
  IntegrationKind.composio: 'composio',
  IntegrationKind.pipedream: 'pipedream',
};
