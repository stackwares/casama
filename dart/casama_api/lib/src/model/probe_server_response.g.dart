// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'probe_server_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProbeServerResponseCWProxy {
  ProbeServerResponse auth(ProbeServerResponseAuthEnum auth);

  ProbeServerResponse host(String host);

  ProbeServerResponse signInHost(String? signInHost);

  ProbeServerResponse oauthAvailable(bool? oauthAvailable);

  ProbeServerResponse appId(String? appId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProbeServerResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProbeServerResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ProbeServerResponse call({
    ProbeServerResponseAuthEnum auth,
    String host,
    String? signInHost,
    bool? oauthAvailable,
    String? appId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProbeServerResponse.copyWith(...)` or call `instanceOfProbeServerResponse.copyWith.fieldName(value)` for a single field.
class _$ProbeServerResponseCWProxyImpl implements _$ProbeServerResponseCWProxy {
  const _$ProbeServerResponseCWProxyImpl(this._value);

  final ProbeServerResponse _value;

  @override
  ProbeServerResponse auth(ProbeServerResponseAuthEnum auth) =>
      call(auth: auth);

  @override
  ProbeServerResponse host(String host) => call(host: host);

  @override
  ProbeServerResponse signInHost(String? signInHost) =>
      call(signInHost: signInHost);

  @override
  ProbeServerResponse oauthAvailable(bool? oauthAvailable) =>
      call(oauthAvailable: oauthAvailable);

  @override
  ProbeServerResponse appId(String? appId) => call(appId: appId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProbeServerResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProbeServerResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProbeServerResponse call({
    Object? auth = const $CopyWithPlaceholder(),
    Object? host = const $CopyWithPlaceholder(),
    Object? signInHost = const $CopyWithPlaceholder(),
    Object? oauthAvailable = const $CopyWithPlaceholder(),
    Object? appId = const $CopyWithPlaceholder(),
  }) {
    return ProbeServerResponse(
      auth: auth == const $CopyWithPlaceholder() || auth == null
          ? _value.auth
          // ignore: cast_nullable_to_non_nullable
          : auth as ProbeServerResponseAuthEnum,
      host: host == const $CopyWithPlaceholder() || host == null
          ? _value.host
          // ignore: cast_nullable_to_non_nullable
          : host as String,
      signInHost: signInHost == const $CopyWithPlaceholder()
          ? _value.signInHost
          // ignore: cast_nullable_to_non_nullable
          : signInHost as String?,
      oauthAvailable: oauthAvailable == const $CopyWithPlaceholder()
          ? _value.oauthAvailable
          // ignore: cast_nullable_to_non_nullable
          : oauthAvailable as bool?,
      appId: appId == const $CopyWithPlaceholder()
          ? _value.appId
          // ignore: cast_nullable_to_non_nullable
          : appId as String?,
    );
  }
}

extension $ProbeServerResponseCopyWith on ProbeServerResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProbeServerResponse.copyWith(...)` or `instanceOfProbeServerResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProbeServerResponseCWProxy get copyWith =>
      _$ProbeServerResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProbeServerResponse _$ProbeServerResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ProbeServerResponse',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['auth', 'host']);
        final val = ProbeServerResponse(
          auth: $checkedConvert(
            'auth',
            (v) => $enumDecode(_$ProbeServerResponseAuthEnumEnumMap, v),
          ),
          host: $checkedConvert('host', (v) => v as String),
          signInHost: $checkedConvert('sign_in_host', (v) => v as String?),
          oauthAvailable: $checkedConvert('oauth_available', (v) => v as bool?),
          appId: $checkedConvert('app_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'signInHost': 'sign_in_host',
        'oauthAvailable': 'oauth_available',
        'appId': 'app_id',
      },
    );

Map<String, dynamic> _$ProbeServerResponseToJson(
  ProbeServerResponse instance,
) => <String, dynamic>{
  'auth': _$ProbeServerResponseAuthEnumEnumMap[instance.auth]!,
  'host': instance.host,
  'sign_in_host': ?instance.signInHost,
  'oauth_available': ?instance.oauthAvailable,
  'app_id': ?instance.appId,
};

const _$ProbeServerResponseAuthEnumEnumMap = {
  ProbeServerResponseAuthEnum.none: 'none',
  ProbeServerResponseAuthEnum.oauth: 'oauth',
  ProbeServerResponseAuthEnum.key: 'key',
};
