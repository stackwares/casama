// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ice_server.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IceServerCWProxy {
  IceServer urls(List<String> urls);

  IceServer username(String? username);

  IceServer credential(String? credential);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IceServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IceServer(...).copyWith(id: 12, name: "My name")
  /// ```
  IceServer call({List<String> urls, String? username, String? credential});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIceServer.copyWith(...)` or call `instanceOfIceServer.copyWith.fieldName(value)` for a single field.
class _$IceServerCWProxyImpl implements _$IceServerCWProxy {
  const _$IceServerCWProxyImpl(this._value);

  final IceServer _value;

  @override
  IceServer urls(List<String> urls) => call(urls: urls);

  @override
  IceServer username(String? username) => call(username: username);

  @override
  IceServer credential(String? credential) => call(credential: credential);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IceServer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IceServer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IceServer call({
    Object? urls = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? credential = const $CopyWithPlaceholder(),
  }) {
    return IceServer(
      urls: urls == const $CopyWithPlaceholder() || urls == null
          ? _value.urls
          // ignore: cast_nullable_to_non_nullable
          : urls as List<String>,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String?,
      credential: credential == const $CopyWithPlaceholder()
          ? _value.credential
          // ignore: cast_nullable_to_non_nullable
          : credential as String?,
    );
  }
}

extension $IceServerCopyWith on IceServer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIceServer.copyWith(...)` or `instanceOfIceServer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IceServerCWProxy get copyWith => _$IceServerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IceServer _$IceServerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IceServer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['urls']);
      final val = IceServer(
        urls: $checkedConvert(
          'urls',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        username: $checkedConvert('username', (v) => v as String?),
        credential: $checkedConvert('credential', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$IceServerToJson(IceServer instance) => <String, dynamic>{
  'urls': instance.urls,
  'username': ?instance.username,
  'credential': ?instance.credential,
};
