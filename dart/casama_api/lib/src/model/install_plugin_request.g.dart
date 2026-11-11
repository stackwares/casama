// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_plugin_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallPluginRequestCWProxy {
  InstallPluginRequest orgId(String orgId);

  InstallPluginRequest botId(String botId);

  InstallPluginRequest url(String url);

  InstallPluginRequest commit(String commit);

  InstallPluginRequest secrets(Map<String, String>? secrets);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallPluginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallPluginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  InstallPluginRequest call({
    String orgId,
    String botId,
    String url,
    String commit,
    Map<String, String>? secrets,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstallPluginRequest.copyWith(...)` or call `instanceOfInstallPluginRequest.copyWith.fieldName(value)` for a single field.
class _$InstallPluginRequestCWProxyImpl
    implements _$InstallPluginRequestCWProxy {
  const _$InstallPluginRequestCWProxyImpl(this._value);

  final InstallPluginRequest _value;

  @override
  InstallPluginRequest orgId(String orgId) => call(orgId: orgId);

  @override
  InstallPluginRequest botId(String botId) => call(botId: botId);

  @override
  InstallPluginRequest url(String url) => call(url: url);

  @override
  InstallPluginRequest commit(String commit) => call(commit: commit);

  @override
  InstallPluginRequest secrets(Map<String, String>? secrets) =>
      call(secrets: secrets);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallPluginRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallPluginRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstallPluginRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
  }) {
    return InstallPluginRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
      secrets: secrets == const $CopyWithPlaceholder()
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as Map<String, String>?,
    );
  }
}

extension $InstallPluginRequestCopyWith on InstallPluginRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstallPluginRequest.copyWith(...)` or `instanceOfInstallPluginRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallPluginRequestCWProxy get copyWith =>
      _$InstallPluginRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallPluginRequest _$InstallPluginRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InstallPluginRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'bot_id', 'url', 'commit']);
  final val = InstallPluginRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    commit: $checkedConvert('commit', (v) => v as String),
    secrets: $checkedConvert(
      'secrets',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String)),
    ),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'botId': 'bot_id'});

Map<String, dynamic> _$InstallPluginRequestToJson(
  InstallPluginRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'bot_id': instance.botId,
  'url': instance.url,
  'commit': instance.commit,
  'secrets': ?instance.secrets,
};
