// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_app_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectAppRequestCWProxy {
  ConnectAppRequest orgId(String orgId);

  ConnectAppRequest appId(String appId);

  ConnectAppRequest method(ConnectAppRequestMethodEnum method);

  ConnectAppRequest apiKey(String? apiKey);

  ConnectAppRequest integrationId(String? integrationId);

  ConnectAppRequest returnToApp(bool? returnToApp);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectAppRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectAppRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectAppRequest call({
    String orgId,
    String appId,
    ConnectAppRequestMethodEnum method,
    String? apiKey,
    String? integrationId,
    bool? returnToApp,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectAppRequest.copyWith(...)` or call `instanceOfConnectAppRequest.copyWith.fieldName(value)` for a single field.
class _$ConnectAppRequestCWProxyImpl implements _$ConnectAppRequestCWProxy {
  const _$ConnectAppRequestCWProxyImpl(this._value);

  final ConnectAppRequest _value;

  @override
  ConnectAppRequest orgId(String orgId) => call(orgId: orgId);

  @override
  ConnectAppRequest appId(String appId) => call(appId: appId);

  @override
  ConnectAppRequest method(ConnectAppRequestMethodEnum method) =>
      call(method: method);

  @override
  ConnectAppRequest apiKey(String? apiKey) => call(apiKey: apiKey);

  @override
  ConnectAppRequest integrationId(String? integrationId) =>
      call(integrationId: integrationId);

  @override
  ConnectAppRequest returnToApp(bool? returnToApp) =>
      call(returnToApp: returnToApp);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectAppRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectAppRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectAppRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? appId = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? apiKey = const $CopyWithPlaceholder(),
    Object? integrationId = const $CopyWithPlaceholder(),
    Object? returnToApp = const $CopyWithPlaceholder(),
  }) {
    return ConnectAppRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      appId: appId == const $CopyWithPlaceholder() || appId == null
          ? _value.appId
          // ignore: cast_nullable_to_non_nullable
          : appId as String,
      method: method == const $CopyWithPlaceholder() || method == null
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as ConnectAppRequestMethodEnum,
      apiKey: apiKey == const $CopyWithPlaceholder()
          ? _value.apiKey
          // ignore: cast_nullable_to_non_nullable
          : apiKey as String?,
      integrationId: integrationId == const $CopyWithPlaceholder()
          ? _value.integrationId
          // ignore: cast_nullable_to_non_nullable
          : integrationId as String?,
      returnToApp: returnToApp == const $CopyWithPlaceholder()
          ? _value.returnToApp
          // ignore: cast_nullable_to_non_nullable
          : returnToApp as bool?,
    );
  }
}

extension $ConnectAppRequestCopyWith on ConnectAppRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectAppRequest.copyWith(...)` or `instanceOfConnectAppRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectAppRequestCWProxy get copyWith =>
      _$ConnectAppRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectAppRequest _$ConnectAppRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ConnectAppRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['org_id', 'app_id', 'method']);
        final val = ConnectAppRequest(
          orgId: $checkedConvert('org_id', (v) => v as String),
          appId: $checkedConvert('app_id', (v) => v as String),
          method: $checkedConvert(
            'method',
            (v) => $enumDecode(_$ConnectAppRequestMethodEnumEnumMap, v),
          ),
          apiKey: $checkedConvert('api_key', (v) => v as String?),
          integrationId: $checkedConvert('integration_id', (v) => v as String?),
          returnToApp: $checkedConvert('return_to_app', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'appId': 'app_id',
        'apiKey': 'api_key',
        'integrationId': 'integration_id',
        'returnToApp': 'return_to_app',
      },
    );

Map<String, dynamic> _$ConnectAppRequestToJson(ConnectAppRequest instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'app_id': instance.appId,
      'method': _$ConnectAppRequestMethodEnumEnumMap[instance.method]!,
      'api_key': ?instance.apiKey,
      'integration_id': ?instance.integrationId,
      'return_to_app': ?instance.returnToApp,
    };

const _$ConnectAppRequestMethodEnumEnumMap = {
  ConnectAppRequestMethodEnum.oauth: 'oauth',
  ConnectAppRequestMethodEnum.apiKey: 'api_key',
  ConnectAppRequestMethodEnum.none: 'none',
  ConnectAppRequestMethodEnum.managed: 'managed',
};
