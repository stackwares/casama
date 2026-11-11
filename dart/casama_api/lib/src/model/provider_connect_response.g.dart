// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_connect_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderConnectResponseCWProxy {
  ProviderConnectResponse redirectUrl(String redirectUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderConnectResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderConnectResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderConnectResponse call({String redirectUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderConnectResponse.copyWith(...)` or call `instanceOfProviderConnectResponse.copyWith.fieldName(value)` for a single field.
class _$ProviderConnectResponseCWProxyImpl
    implements _$ProviderConnectResponseCWProxy {
  const _$ProviderConnectResponseCWProxyImpl(this._value);

  final ProviderConnectResponse _value;

  @override
  ProviderConnectResponse redirectUrl(String redirectUrl) =>
      call(redirectUrl: redirectUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderConnectResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderConnectResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderConnectResponse call({
    Object? redirectUrl = const $CopyWithPlaceholder(),
  }) {
    return ProviderConnectResponse(
      redirectUrl:
          redirectUrl == const $CopyWithPlaceholder() || redirectUrl == null
          ? _value.redirectUrl
          // ignore: cast_nullable_to_non_nullable
          : redirectUrl as String,
    );
  }
}

extension $ProviderConnectResponseCopyWith on ProviderConnectResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderConnectResponse.copyWith(...)` or `instanceOfProviderConnectResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderConnectResponseCWProxy get copyWith =>
      _$ProviderConnectResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderConnectResponse _$ProviderConnectResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProviderConnectResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['redirect_url']);
  final val = ProviderConnectResponse(
    redirectUrl: $checkedConvert('redirect_url', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'redirectUrl': 'redirect_url'});

Map<String, dynamic> _$ProviderConnectResponseToJson(
  ProviderConnectResponse instance,
) => <String, dynamic>{'redirect_url': instance.redirectUrl};
