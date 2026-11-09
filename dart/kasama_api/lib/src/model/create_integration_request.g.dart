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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateIntegrationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateIntegrationRequest call({
    String orgId,
    IntegrationKind kind,
    String name,
    Map<String, Object?> config,
    String? secret,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateIntegrationRequest.copyWith(...)` or call `instanceOfCreateIntegrationRequest.copyWith.fieldName(value)` for a single field.
class _$CreateIntegrationRequestCWProxyImpl
    implements _$CreateIntegrationRequestCWProxy {
  const _$CreateIntegrationRequestCWProxyImpl(this._value);

  final CreateIntegrationRequest _value;

  @override
  CreateIntegrationRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateIntegrationRequest kind(IntegrationKind kind) => call(kind: kind);

  @override
  CreateIntegrationRequest name(String name) => call(name: name);

  @override
  CreateIntegrationRequest config(Map<String, Object?> config) =>
      call(config: config);

  @override
  CreateIntegrationRequest secret(String? secret) => call(secret: secret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateIntegrationRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateIntegrationRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateIntegrationRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? config = const $CopyWithPlaceholder(),
    Object? secret = const $CopyWithPlaceholder(),
  }) {
    return CreateIntegrationRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as IntegrationKind,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      config: config == const $CopyWithPlaceholder() || config == null
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateIntegrationRequest.copyWith(...)` or `instanceOfCreateIntegrationRequest.copyWith.fieldName(...)`.
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
