// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_secret_store_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetSecretStoreRequestCWProxy {
  SetSecretStoreRequest siteUrl(String siteUrl);

  SetSecretStoreRequest projectId(String projectId);

  SetSecretStoreRequest environment(String? environment);

  SetSecretStoreRequest secretPath(String? secretPath);

  SetSecretStoreRequest clientId(String clientId);

  SetSecretStoreRequest clientSecret(String clientSecret);

  SetSecretStoreRequest moveExisting(bool? moveExisting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetSecretStoreRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetSecretStoreRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetSecretStoreRequest call({
    String siteUrl,
    String projectId,
    String? environment,
    String? secretPath,
    String clientId,
    String clientSecret,
    bool? moveExisting,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetSecretStoreRequest.copyWith(...)` or call `instanceOfSetSecretStoreRequest.copyWith.fieldName(value)` for a single field.
class _$SetSecretStoreRequestCWProxyImpl
    implements _$SetSecretStoreRequestCWProxy {
  const _$SetSecretStoreRequestCWProxyImpl(this._value);

  final SetSecretStoreRequest _value;

  @override
  SetSecretStoreRequest siteUrl(String siteUrl) => call(siteUrl: siteUrl);

  @override
  SetSecretStoreRequest projectId(String projectId) =>
      call(projectId: projectId);

  @override
  SetSecretStoreRequest environment(String? environment) =>
      call(environment: environment);

  @override
  SetSecretStoreRequest secretPath(String? secretPath) =>
      call(secretPath: secretPath);

  @override
  SetSecretStoreRequest clientId(String clientId) => call(clientId: clientId);

  @override
  SetSecretStoreRequest clientSecret(String clientSecret) =>
      call(clientSecret: clientSecret);

  @override
  SetSecretStoreRequest moveExisting(bool? moveExisting) =>
      call(moveExisting: moveExisting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetSecretStoreRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetSecretStoreRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetSecretStoreRequest call({
    Object? siteUrl = const $CopyWithPlaceholder(),
    Object? projectId = const $CopyWithPlaceholder(),
    Object? environment = const $CopyWithPlaceholder(),
    Object? secretPath = const $CopyWithPlaceholder(),
    Object? clientId = const $CopyWithPlaceholder(),
    Object? clientSecret = const $CopyWithPlaceholder(),
    Object? moveExisting = const $CopyWithPlaceholder(),
  }) {
    return SetSecretStoreRequest(
      siteUrl: siteUrl == const $CopyWithPlaceholder() || siteUrl == null
          ? _value.siteUrl
          // ignore: cast_nullable_to_non_nullable
          : siteUrl as String,
      projectId: projectId == const $CopyWithPlaceholder() || projectId == null
          ? _value.projectId
          // ignore: cast_nullable_to_non_nullable
          : projectId as String,
      environment: environment == const $CopyWithPlaceholder()
          ? _value.environment
          // ignore: cast_nullable_to_non_nullable
          : environment as String?,
      secretPath: secretPath == const $CopyWithPlaceholder()
          ? _value.secretPath
          // ignore: cast_nullable_to_non_nullable
          : secretPath as String?,
      clientId: clientId == const $CopyWithPlaceholder() || clientId == null
          ? _value.clientId
          // ignore: cast_nullable_to_non_nullable
          : clientId as String,
      clientSecret:
          clientSecret == const $CopyWithPlaceholder() || clientSecret == null
          ? _value.clientSecret
          // ignore: cast_nullable_to_non_nullable
          : clientSecret as String,
      moveExisting: moveExisting == const $CopyWithPlaceholder()
          ? _value.moveExisting
          // ignore: cast_nullable_to_non_nullable
          : moveExisting as bool?,
    );
  }
}

extension $SetSecretStoreRequestCopyWith on SetSecretStoreRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetSecretStoreRequest.copyWith(...)` or `instanceOfSetSecretStoreRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetSecretStoreRequestCWProxy get copyWith =>
      _$SetSecretStoreRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetSecretStoreRequest _$SetSecretStoreRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SetSecretStoreRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'site_url',
        'project_id',
        'client_id',
        'client_secret',
      ],
    );
    final val = SetSecretStoreRequest(
      siteUrl: $checkedConvert('site_url', (v) => v as String),
      projectId: $checkedConvert('project_id', (v) => v as String),
      environment: $checkedConvert('environment', (v) => v as String?),
      secretPath: $checkedConvert('secret_path', (v) => v as String?),
      clientId: $checkedConvert('client_id', (v) => v as String),
      clientSecret: $checkedConvert('client_secret', (v) => v as String),
      moveExisting: $checkedConvert('move_existing', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'siteUrl': 'site_url',
    'projectId': 'project_id',
    'secretPath': 'secret_path',
    'clientId': 'client_id',
    'clientSecret': 'client_secret',
    'moveExisting': 'move_existing',
  },
);

Map<String, dynamic> _$SetSecretStoreRequestToJson(
  SetSecretStoreRequest instance,
) => <String, dynamic>{
  'site_url': instance.siteUrl,
  'project_id': instance.projectId,
  'environment': ?instance.environment,
  'secret_path': ?instance.secretPath,
  'client_id': instance.clientId,
  'client_secret': instance.clientSecret,
  'move_existing': ?instance.moveExisting,
};
