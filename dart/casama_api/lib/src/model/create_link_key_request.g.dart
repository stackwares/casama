// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_link_key_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateLinkKeyRequestCWProxy {
  CreateLinkKeyRequest instanceName(String instanceName);

  CreateLinkKeyRequest scopes(List<CreateLinkKeyRequestScopesEnum>? scopes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateLinkKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateLinkKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateLinkKeyRequest call({
    String instanceName,
    List<CreateLinkKeyRequestScopesEnum>? scopes,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateLinkKeyRequest.copyWith(...)` or call `instanceOfCreateLinkKeyRequest.copyWith.fieldName(value)` for a single field.
class _$CreateLinkKeyRequestCWProxyImpl
    implements _$CreateLinkKeyRequestCWProxy {
  const _$CreateLinkKeyRequestCWProxyImpl(this._value);

  final CreateLinkKeyRequest _value;

  @override
  CreateLinkKeyRequest instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  CreateLinkKeyRequest scopes(List<CreateLinkKeyRequestScopesEnum>? scopes) =>
      call(scopes: scopes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateLinkKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateLinkKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateLinkKeyRequest call({
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? scopes = const $CopyWithPlaceholder(),
  }) {
    return CreateLinkKeyRequest(
      instanceName:
          instanceName == const $CopyWithPlaceholder() || instanceName == null
          ? _value.instanceName
          // ignore: cast_nullable_to_non_nullable
          : instanceName as String,
      scopes: scopes == const $CopyWithPlaceholder()
          ? _value.scopes
          // ignore: cast_nullable_to_non_nullable
          : scopes as List<CreateLinkKeyRequestScopesEnum>?,
    );
  }
}

extension $CreateLinkKeyRequestCopyWith on CreateLinkKeyRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateLinkKeyRequest.copyWith(...)` or `instanceOfCreateLinkKeyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateLinkKeyRequestCWProxy get copyWith =>
      _$CreateLinkKeyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLinkKeyRequest _$CreateLinkKeyRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateLinkKeyRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['instance_name']);
  final val = CreateLinkKeyRequest(
    instanceName: $checkedConvert('instance_name', (v) => v as String),
    scopes: $checkedConvert(
      'scopes',
      (v) => (v as List<dynamic>?)
          ?.map((e) => $enumDecode(_$CreateLinkKeyRequestScopesEnumEnumMap, e))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'instanceName': 'instance_name'});

Map<String, dynamic> _$CreateLinkKeyRequestToJson(
  CreateLinkKeyRequest instance,
) => <String, dynamic>{
  'instance_name': instance.instanceName,
  'scopes': ?instance.scopes
      ?.map((e) => _$CreateLinkKeyRequestScopesEnumEnumMap[e]!)
      .toList(),
};

const _$CreateLinkKeyRequestScopesEnumEnumMap = {
  CreateLinkKeyRequestScopesEnum.computers: 'computers',
  CreateLinkKeyRequestScopesEnum.models: 'models',
  CreateLinkKeyRequestScopesEnum.remoteAccess: 'remote_access',
  CreateLinkKeyRequestScopesEnum.push: 'push',
};
