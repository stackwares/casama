// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_app_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectAppResponseCWProxy {
  ConnectAppResponse status(ConnectAppResponseStatusEnum status);

  ConnectAppResponse integration(Integration? integration);

  ConnectAppResponse authorizeUrl(String? authorizeUrl);

  ConnectAppResponse flowId(String? flowId);

  ConnectAppResponse error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectAppResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectAppResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectAppResponse call({
    ConnectAppResponseStatusEnum status,
    Integration? integration,
    String? authorizeUrl,
    String? flowId,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectAppResponse.copyWith(...)` or call `instanceOfConnectAppResponse.copyWith.fieldName(value)` for a single field.
class _$ConnectAppResponseCWProxyImpl implements _$ConnectAppResponseCWProxy {
  const _$ConnectAppResponseCWProxyImpl(this._value);

  final ConnectAppResponse _value;

  @override
  ConnectAppResponse status(ConnectAppResponseStatusEnum status) =>
      call(status: status);

  @override
  ConnectAppResponse integration(Integration? integration) =>
      call(integration: integration);

  @override
  ConnectAppResponse authorizeUrl(String? authorizeUrl) =>
      call(authorizeUrl: authorizeUrl);

  @override
  ConnectAppResponse flowId(String? flowId) => call(flowId: flowId);

  @override
  ConnectAppResponse error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectAppResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectAppResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectAppResponse call({
    Object? status = const $CopyWithPlaceholder(),
    Object? integration = const $CopyWithPlaceholder(),
    Object? authorizeUrl = const $CopyWithPlaceholder(),
    Object? flowId = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return ConnectAppResponse(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ConnectAppResponseStatusEnum,
      integration: integration == const $CopyWithPlaceholder()
          ? _value.integration
          // ignore: cast_nullable_to_non_nullable
          : integration as Integration?,
      authorizeUrl: authorizeUrl == const $CopyWithPlaceholder()
          ? _value.authorizeUrl
          // ignore: cast_nullable_to_non_nullable
          : authorizeUrl as String?,
      flowId: flowId == const $CopyWithPlaceholder()
          ? _value.flowId
          // ignore: cast_nullable_to_non_nullable
          : flowId as String?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $ConnectAppResponseCopyWith on ConnectAppResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectAppResponse.copyWith(...)` or `instanceOfConnectAppResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectAppResponseCWProxy get copyWith =>
      _$ConnectAppResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectAppResponse _$ConnectAppResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConnectAppResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['status']);
  final val = ConnectAppResponse(
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$ConnectAppResponseStatusEnumEnumMap, v),
    ),
    integration: $checkedConvert(
      'integration',
      (v) => v == null ? null : Integration.fromJson(v as Map<String, dynamic>),
    ),
    authorizeUrl: $checkedConvert('authorize_url', (v) => v as String?),
    flowId: $checkedConvert('flow_id', (v) => v as String?),
    error: $checkedConvert('error', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'authorizeUrl': 'authorize_url', 'flowId': 'flow_id'});

Map<String, dynamic> _$ConnectAppResponseToJson(ConnectAppResponse instance) =>
    <String, dynamic>{
      'status': _$ConnectAppResponseStatusEnumEnumMap[instance.status]!,
      'integration': ?instance.integration?.toJson(),
      'authorize_url': ?instance.authorizeUrl,
      'flow_id': ?instance.flowId,
      'error': ?instance.error,
    };

const _$ConnectAppResponseStatusEnumEnumMap = {
  ConnectAppResponseStatusEnum.connected: 'connected',
  ConnectAppResponseStatusEnum.authorize: 'authorize',
  ConnectAppResponseStatusEnum.error: 'error',
};
