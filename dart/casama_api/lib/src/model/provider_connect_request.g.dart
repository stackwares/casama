// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_connect_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderConnectRequestCWProxy {
  ProviderConnectRequest app(String app);

  ProviderConnectRequest returnToApp(bool? returnToApp);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderConnectRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderConnectRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderConnectRequest call({String app, bool? returnToApp});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderConnectRequest.copyWith(...)` or call `instanceOfProviderConnectRequest.copyWith.fieldName(value)` for a single field.
class _$ProviderConnectRequestCWProxyImpl
    implements _$ProviderConnectRequestCWProxy {
  const _$ProviderConnectRequestCWProxyImpl(this._value);

  final ProviderConnectRequest _value;

  @override
  ProviderConnectRequest app(String app) => call(app: app);

  @override
  ProviderConnectRequest returnToApp(bool? returnToApp) =>
      call(returnToApp: returnToApp);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderConnectRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderConnectRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderConnectRequest call({
    Object? app = const $CopyWithPlaceholder(),
    Object? returnToApp = const $CopyWithPlaceholder(),
  }) {
    return ProviderConnectRequest(
      app: app == const $CopyWithPlaceholder() || app == null
          ? _value.app
          // ignore: cast_nullable_to_non_nullable
          : app as String,
      returnToApp: returnToApp == const $CopyWithPlaceholder()
          ? _value.returnToApp
          // ignore: cast_nullable_to_non_nullable
          : returnToApp as bool?,
    );
  }
}

extension $ProviderConnectRequestCopyWith on ProviderConnectRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderConnectRequest.copyWith(...)` or `instanceOfProviderConnectRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderConnectRequestCWProxy get copyWith =>
      _$ProviderConnectRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderConnectRequest _$ProviderConnectRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProviderConnectRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['app']);
  final val = ProviderConnectRequest(
    app: $checkedConvert('app', (v) => v as String),
    returnToApp: $checkedConvert('return_to_app', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'returnToApp': 'return_to_app'});

Map<String, dynamic> _$ProviderConnectRequestToJson(
  ProviderConnectRequest instance,
) => <String, dynamic>{
  'app': instance.app,
  'return_to_app': ?instance.returnToApp,
};
