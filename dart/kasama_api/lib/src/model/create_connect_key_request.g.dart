// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_connect_key_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateConnectKeyRequestCWProxy {
  CreateConnectKeyRequest instanceName(String instanceName);

  CreateConnectKeyRequest scopes(
    List<CreateConnectKeyRequestScopesEnum>? scopes,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateConnectKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateConnectKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateConnectKeyRequest call({
    String instanceName,
    List<CreateConnectKeyRequestScopesEnum>? scopes,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateConnectKeyRequest.copyWith(...)` or call `instanceOfCreateConnectKeyRequest.copyWith.fieldName(value)` for a single field.
class _$CreateConnectKeyRequestCWProxyImpl
    implements _$CreateConnectKeyRequestCWProxy {
  const _$CreateConnectKeyRequestCWProxyImpl(this._value);

  final CreateConnectKeyRequest _value;

  @override
  CreateConnectKeyRequest instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  CreateConnectKeyRequest scopes(
    List<CreateConnectKeyRequestScopesEnum>? scopes,
  ) => call(scopes: scopes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateConnectKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateConnectKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateConnectKeyRequest call({
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? scopes = const $CopyWithPlaceholder(),
  }) {
    return CreateConnectKeyRequest(
      instanceName:
          instanceName == const $CopyWithPlaceholder() || instanceName == null
          ? _value.instanceName
          // ignore: cast_nullable_to_non_nullable
          : instanceName as String,
      scopes: scopes == const $CopyWithPlaceholder()
          ? _value.scopes
          // ignore: cast_nullable_to_non_nullable
          : scopes as List<CreateConnectKeyRequestScopesEnum>?,
    );
  }
}

extension $CreateConnectKeyRequestCopyWith on CreateConnectKeyRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateConnectKeyRequest.copyWith(...)` or `instanceOfCreateConnectKeyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateConnectKeyRequestCWProxy get copyWith =>
      _$CreateConnectKeyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateConnectKeyRequest _$CreateConnectKeyRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateConnectKeyRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['instance_name']);
  final val = CreateConnectKeyRequest(
    instanceName: $checkedConvert('instance_name', (v) => v as String),
    scopes: $checkedConvert(
      'scopes',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => $enumDecode(_$CreateConnectKeyRequestScopesEnumEnumMap, e),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'instanceName': 'instance_name'});

Map<String, dynamic> _$CreateConnectKeyRequestToJson(
  CreateConnectKeyRequest instance,
) => <String, dynamic>{
  'instance_name': instance.instanceName,
  'scopes': ?instance.scopes
      ?.map((e) => _$CreateConnectKeyRequestScopesEnumEnumMap[e]!)
      .toList(),
};

const _$CreateConnectKeyRequestScopesEnumEnumMap = {
  CreateConnectKeyRequestScopesEnum.computers: 'computers',
  CreateConnectKeyRequestScopesEnum.models: 'models',
};
