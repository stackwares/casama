// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_pack_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallPackRequestCWProxy {
  InstallPackRequest orgId(String orgId);

  InstallPackRequest url(String? url);

  InstallPackRequest commit(String? commit);

  InstallPackRequest galleryId(String? galleryId);

  InstallPackRequest shareToken(String? shareToken);

  InstallPackRequest files(List<PackFileInput>? files);

  InstallPackRequest skip(List<PackItemRef>? skip);

  InstallPackRequest inputs(Map<String, String>? inputs);

  InstallPackRequest secrets(Map<String, String>? secrets);

  InstallPackRequest settings(Map<String, String>? settings);

  InstallPackRequest botId(String? botId);

  InstallPackRequest routinesOn(bool? routinesOn);

  InstallPackRequest deviceId(String? deviceId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  InstallPackRequest call({
    String orgId,
    String? url,
    String? commit,
    String? galleryId,
    String? shareToken,
    List<PackFileInput>? files,
    List<PackItemRef>? skip,
    Map<String, String>? inputs,
    Map<String, String>? secrets,
    Map<String, String>? settings,
    String? botId,
    bool? routinesOn,
    String? deviceId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstallPackRequest.copyWith(...)` or call `instanceOfInstallPackRequest.copyWith.fieldName(value)` for a single field.
class _$InstallPackRequestCWProxyImpl implements _$InstallPackRequestCWProxy {
  const _$InstallPackRequestCWProxyImpl(this._value);

  final InstallPackRequest _value;

  @override
  InstallPackRequest orgId(String orgId) => call(orgId: orgId);

  @override
  InstallPackRequest url(String? url) => call(url: url);

  @override
  InstallPackRequest commit(String? commit) => call(commit: commit);

  @override
  InstallPackRequest galleryId(String? galleryId) => call(galleryId: galleryId);

  @override
  InstallPackRequest shareToken(String? shareToken) =>
      call(shareToken: shareToken);

  @override
  InstallPackRequest files(List<PackFileInput>? files) => call(files: files);

  @override
  InstallPackRequest skip(List<PackItemRef>? skip) => call(skip: skip);

  @override
  InstallPackRequest inputs(Map<String, String>? inputs) =>
      call(inputs: inputs);

  @override
  InstallPackRequest secrets(Map<String, String>? secrets) =>
      call(secrets: secrets);

  @override
  InstallPackRequest settings(Map<String, String>? settings) =>
      call(settings: settings);

  @override
  InstallPackRequest botId(String? botId) => call(botId: botId);

  @override
  InstallPackRequest routinesOn(bool? routinesOn) =>
      call(routinesOn: routinesOn);

  @override
  InstallPackRequest deviceId(String? deviceId) => call(deviceId: deviceId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstallPackRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? galleryId = const $CopyWithPlaceholder(),
    Object? shareToken = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
    Object? skip = const $CopyWithPlaceholder(),
    Object? inputs = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
    Object? settings = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? routinesOn = const $CopyWithPlaceholder(),
    Object? deviceId = const $CopyWithPlaceholder(),
  }) {
    return InstallPackRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      commit: commit == const $CopyWithPlaceholder()
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String?,
      galleryId: galleryId == const $CopyWithPlaceholder()
          ? _value.galleryId
          // ignore: cast_nullable_to_non_nullable
          : galleryId as String?,
      shareToken: shareToken == const $CopyWithPlaceholder()
          ? _value.shareToken
          // ignore: cast_nullable_to_non_nullable
          : shareToken as String?,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<PackFileInput>?,
      skip: skip == const $CopyWithPlaceholder()
          ? _value.skip
          // ignore: cast_nullable_to_non_nullable
          : skip as List<PackItemRef>?,
      inputs: inputs == const $CopyWithPlaceholder()
          ? _value.inputs
          // ignore: cast_nullable_to_non_nullable
          : inputs as Map<String, String>?,
      secrets: secrets == const $CopyWithPlaceholder()
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as Map<String, String>?,
      settings: settings == const $CopyWithPlaceholder()
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as Map<String, String>?,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      routinesOn: routinesOn == const $CopyWithPlaceholder()
          ? _value.routinesOn
          // ignore: cast_nullable_to_non_nullable
          : routinesOn as bool?,
      deviceId: deviceId == const $CopyWithPlaceholder()
          ? _value.deviceId
          // ignore: cast_nullable_to_non_nullable
          : deviceId as String?,
    );
  }
}

extension $InstallPackRequestCopyWith on InstallPackRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstallPackRequest.copyWith(...)` or `instanceOfInstallPackRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallPackRequestCWProxy get copyWith =>
      _$InstallPackRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallPackRequest _$InstallPackRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InstallPackRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['org_id']);
        final val = InstallPackRequest(
          orgId: $checkedConvert('org_id', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String?),
          commit: $checkedConvert('commit', (v) => v as String?),
          galleryId: $checkedConvert('gallery_id', (v) => v as String?),
          shareToken: $checkedConvert('share_token', (v) => v as String?),
          files: $checkedConvert(
            'files',
            (v) => (v as List<dynamic>?)
                ?.map((e) => PackFileInput.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          skip: $checkedConvert(
            'skip',
            (v) => (v as List<dynamic>?)
                ?.map((e) => PackItemRef.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          inputs: $checkedConvert(
            'inputs',
            (v) => (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as String),
            ),
          ),
          secrets: $checkedConvert(
            'secrets',
            (v) => (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as String),
            ),
          ),
          settings: $checkedConvert(
            'settings',
            (v) => (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as String),
            ),
          ),
          botId: $checkedConvert('bot_id', (v) => v as String?),
          routinesOn: $checkedConvert('routines_on', (v) => v as bool?),
          deviceId: $checkedConvert('device_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'galleryId': 'gallery_id',
        'shareToken': 'share_token',
        'botId': 'bot_id',
        'routinesOn': 'routines_on',
        'deviceId': 'device_id',
      },
    );

Map<String, dynamic> _$InstallPackRequestToJson(InstallPackRequest instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'url': ?instance.url,
      'commit': ?instance.commit,
      'gallery_id': ?instance.galleryId,
      'share_token': ?instance.shareToken,
      'files': ?instance.files?.map((e) => e.toJson()).toList(),
      'skip': ?instance.skip?.map((e) => e.toJson()).toList(),
      'inputs': ?instance.inputs,
      'secrets': ?instance.secrets,
      'settings': ?instance.settings,
      'bot_id': ?instance.botId,
      'routines_on': ?instance.routinesOn,
      'device_id': ?instance.deviceId,
    };
