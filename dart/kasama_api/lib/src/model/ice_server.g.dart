// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ice_server.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IceServerCWProxy {
  IceServer urls(List<String> urls);

  IceServer username(String? username);

  IceServer credential(String? credential);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IceServer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IceServer(...).copyWith(id: 12, name: "My name")
  /// ````
  IceServer call({List<String> urls, String? username, String? credential});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIceServer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIceServer.copyWith.fieldName(...)`
class _$IceServerCWProxyImpl implements _$IceServerCWProxy {
  const _$IceServerCWProxyImpl(this._value);

  final IceServer _value;

  @override
  IceServer urls(List<String> urls) => this(urls: urls);

  @override
  IceServer username(String? username) => this(username: username);

  @override
  IceServer credential(String? credential) => this(credential: credential);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IceServer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IceServer(...).copyWith(id: 12, name: "My name")
  /// ````
  IceServer call({
    Object? urls = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? credential = const $CopyWithPlaceholder(),
  }) {
    return IceServer(
      urls: urls == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfIceServer.copyWith(...)` or like so:`instanceOfIceServer.copyWith.fieldName(...)`.
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
