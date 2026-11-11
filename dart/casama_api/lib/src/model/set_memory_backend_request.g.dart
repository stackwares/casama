// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_memory_backend_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetMemoryBackendRequestCWProxy {
  SetMemoryBackendRequest provider(
    SetMemoryBackendRequestProviderEnum provider,
  );

  SetMemoryBackendRequest apiKey(String apiKey);

  SetMemoryBackendRequest baseUrl(String? baseUrl);

  SetMemoryBackendRequest workspace(String? workspace);

  SetMemoryBackendRequest copyExisting(bool? copyExisting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetMemoryBackendRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetMemoryBackendRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetMemoryBackendRequest call({
    SetMemoryBackendRequestProviderEnum provider,
    String apiKey,
    String? baseUrl,
    String? workspace,
    bool? copyExisting,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetMemoryBackendRequest.copyWith(...)` or call `instanceOfSetMemoryBackendRequest.copyWith.fieldName(value)` for a single field.
class _$SetMemoryBackendRequestCWProxyImpl
    implements _$SetMemoryBackendRequestCWProxy {
  const _$SetMemoryBackendRequestCWProxyImpl(this._value);

  final SetMemoryBackendRequest _value;

  @override
  SetMemoryBackendRequest provider(
    SetMemoryBackendRequestProviderEnum provider,
  ) => call(provider: provider);

  @override
  SetMemoryBackendRequest apiKey(String apiKey) => call(apiKey: apiKey);

  @override
  SetMemoryBackendRequest baseUrl(String? baseUrl) => call(baseUrl: baseUrl);

  @override
  SetMemoryBackendRequest workspace(String? workspace) =>
      call(workspace: workspace);

  @override
  SetMemoryBackendRequest copyExisting(bool? copyExisting) =>
      call(copyExisting: copyExisting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetMemoryBackendRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetMemoryBackendRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetMemoryBackendRequest call({
    Object? provider = const $CopyWithPlaceholder(),
    Object? apiKey = const $CopyWithPlaceholder(),
    Object? baseUrl = const $CopyWithPlaceholder(),
    Object? workspace = const $CopyWithPlaceholder(),
    Object? copyExisting = const $CopyWithPlaceholder(),
  }) {
    return SetMemoryBackendRequest(
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as SetMemoryBackendRequestProviderEnum,
      apiKey: apiKey == const $CopyWithPlaceholder() || apiKey == null
          ? _value.apiKey
          // ignore: cast_nullable_to_non_nullable
          : apiKey as String,
      baseUrl: baseUrl == const $CopyWithPlaceholder()
          ? _value.baseUrl
          // ignore: cast_nullable_to_non_nullable
          : baseUrl as String?,
      workspace: workspace == const $CopyWithPlaceholder()
          ? _value.workspace
          // ignore: cast_nullable_to_non_nullable
          : workspace as String?,
      copyExisting: copyExisting == const $CopyWithPlaceholder()
          ? _value.copyExisting
          // ignore: cast_nullable_to_non_nullable
          : copyExisting as bool?,
    );
  }
}

extension $SetMemoryBackendRequestCopyWith on SetMemoryBackendRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetMemoryBackendRequest.copyWith(...)` or `instanceOfSetMemoryBackendRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetMemoryBackendRequestCWProxy get copyWith =>
      _$SetMemoryBackendRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetMemoryBackendRequest _$SetMemoryBackendRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SetMemoryBackendRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['provider', 'api_key']);
    final val = SetMemoryBackendRequest(
      provider: $checkedConvert(
        'provider',
        (v) => $enumDecode(_$SetMemoryBackendRequestProviderEnumEnumMap, v),
      ),
      apiKey: $checkedConvert('api_key', (v) => v as String),
      baseUrl: $checkedConvert('base_url', (v) => v as String?),
      workspace: $checkedConvert('workspace', (v) => v as String?),
      copyExisting: $checkedConvert('copy_existing', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'apiKey': 'api_key',
    'baseUrl': 'base_url',
    'copyExisting': 'copy_existing',
  },
);

Map<String, dynamic> _$SetMemoryBackendRequestToJson(
  SetMemoryBackendRequest instance,
) => <String, dynamic>{
  'provider': _$SetMemoryBackendRequestProviderEnumEnumMap[instance.provider]!,
  'api_key': instance.apiKey,
  'base_url': ?instance.baseUrl,
  'workspace': ?instance.workspace,
  'copy_existing': ?instance.copyExisting,
};

const _$SetMemoryBackendRequestProviderEnumEnumMap = {
  SetMemoryBackendRequestProviderEnum.honcho: 'honcho',
  SetMemoryBackendRequestProviderEnum.supermemory: 'supermemory',
};
