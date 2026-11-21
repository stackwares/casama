// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_server_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectServerRequestCWProxy {
  ConnectServerRequest orgId(String orgId);

  ConnectServerRequest url(String url);

  ConnectServerRequest name(String name);

  ConnectServerRequest method(ConnectServerRequestMethodEnum method);

  ConnectServerRequest apiKey(String? apiKey);

  ConnectServerRequest authHeader(String? authHeader);

  ConnectServerRequest privateUrl(bool? privateUrl);

  ConnectServerRequest botId(String? botId);

  ConnectServerRequest returnToApp(bool? returnToApp);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectServerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectServerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectServerRequest call({
    String orgId,
    String url,
    String name,
    ConnectServerRequestMethodEnum method,
    String? apiKey,
    String? authHeader,
    bool? privateUrl,
    String? botId,
    bool? returnToApp,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectServerRequest.copyWith(...)` or call `instanceOfConnectServerRequest.copyWith.fieldName(value)` for a single field.
class _$ConnectServerRequestCWProxyImpl
    implements _$ConnectServerRequestCWProxy {
  const _$ConnectServerRequestCWProxyImpl(this._value);

  final ConnectServerRequest _value;

  @override
  ConnectServerRequest orgId(String orgId) => call(orgId: orgId);

  @override
  ConnectServerRequest url(String url) => call(url: url);

  @override
  ConnectServerRequest name(String name) => call(name: name);

  @override
  ConnectServerRequest method(ConnectServerRequestMethodEnum method) =>
      call(method: method);

  @override
  ConnectServerRequest apiKey(String? apiKey) => call(apiKey: apiKey);

  @override
  ConnectServerRequest authHeader(String? authHeader) =>
      call(authHeader: authHeader);

  @override
  ConnectServerRequest privateUrl(bool? privateUrl) =>
      call(privateUrl: privateUrl);

  @override
  ConnectServerRequest botId(String? botId) => call(botId: botId);

  @override
  ConnectServerRequest returnToApp(bool? returnToApp) =>
      call(returnToApp: returnToApp);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectServerRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectServerRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectServerRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? apiKey = const $CopyWithPlaceholder(),
    Object? authHeader = const $CopyWithPlaceholder(),
    Object? privateUrl = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? returnToApp = const $CopyWithPlaceholder(),
  }) {
    return ConnectServerRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      method: method == const $CopyWithPlaceholder() || method == null
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as ConnectServerRequestMethodEnum,
      apiKey: apiKey == const $CopyWithPlaceholder()
          ? _value.apiKey
          // ignore: cast_nullable_to_non_nullable
          : apiKey as String?,
      authHeader: authHeader == const $CopyWithPlaceholder()
          ? _value.authHeader
          // ignore: cast_nullable_to_non_nullable
          : authHeader as String?,
      privateUrl: privateUrl == const $CopyWithPlaceholder()
          ? _value.privateUrl
          // ignore: cast_nullable_to_non_nullable
          : privateUrl as bool?,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      returnToApp: returnToApp == const $CopyWithPlaceholder()
          ? _value.returnToApp
          // ignore: cast_nullable_to_non_nullable
          : returnToApp as bool?,
    );
  }
}

extension $ConnectServerRequestCopyWith on ConnectServerRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectServerRequest.copyWith(...)` or `instanceOfConnectServerRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectServerRequestCWProxy get copyWith =>
      _$ConnectServerRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectServerRequest _$ConnectServerRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ConnectServerRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'url', 'name', 'method']);
    final val = ConnectServerRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      method: $checkedConvert(
        'method',
        (v) => $enumDecode(_$ConnectServerRequestMethodEnumEnumMap, v),
      ),
      apiKey: $checkedConvert('api_key', (v) => v as String?),
      authHeader: $checkedConvert('auth_header', (v) => v as String?),
      privateUrl: $checkedConvert('private_url', (v) => v as bool?),
      botId: $checkedConvert('bot_id', (v) => v as String?),
      returnToApp: $checkedConvert('return_to_app', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'apiKey': 'api_key',
    'authHeader': 'auth_header',
    'privateUrl': 'private_url',
    'botId': 'bot_id',
    'returnToApp': 'return_to_app',
  },
);

Map<String, dynamic> _$ConnectServerRequestToJson(
  ConnectServerRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'url': instance.url,
  'name': instance.name,
  'method': _$ConnectServerRequestMethodEnumEnumMap[instance.method]!,
  'api_key': ?instance.apiKey,
  'auth_header': ?instance.authHeader,
  'private_url': ?instance.privateUrl,
  'bot_id': ?instance.botId,
  'return_to_app': ?instance.returnToApp,
};

const _$ConnectServerRequestMethodEnumEnumMap = {
  ConnectServerRequestMethodEnum.oauth: 'oauth',
  ConnectServerRequestMethodEnum.apiKey: 'api_key',
  ConnectServerRequestMethodEnum.none: 'none',
};
