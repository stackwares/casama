// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_app_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemoteAppConfigCWProxy {
  RemoteAppConfig minVersions(RemoteAppConfigMinVersions minVersions);

  RemoteAppConfig updateUrls(RemoteAppConfigUpdateUrls updateUrls);

  RemoteAppConfig maintenance(RemoteAppConfigMaintenance? maintenance);

  RemoteAppConfig announcements(List<Announcement> announcements);

  RemoteAppConfig flags(Map<String, bool> flags);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  RemoteAppConfig call({
    RemoteAppConfigMinVersions minVersions,
    RemoteAppConfigUpdateUrls updateUrls,
    RemoteAppConfigMaintenance? maintenance,
    List<Announcement> announcements,
    Map<String, bool> flags,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemoteAppConfig.copyWith(...)` or call `instanceOfRemoteAppConfig.copyWith.fieldName(value)` for a single field.
class _$RemoteAppConfigCWProxyImpl implements _$RemoteAppConfigCWProxy {
  const _$RemoteAppConfigCWProxyImpl(this._value);

  final RemoteAppConfig _value;

  @override
  RemoteAppConfig minVersions(RemoteAppConfigMinVersions minVersions) =>
      call(minVersions: minVersions);

  @override
  RemoteAppConfig updateUrls(RemoteAppConfigUpdateUrls updateUrls) =>
      call(updateUrls: updateUrls);

  @override
  RemoteAppConfig maintenance(RemoteAppConfigMaintenance? maintenance) =>
      call(maintenance: maintenance);

  @override
  RemoteAppConfig announcements(List<Announcement> announcements) =>
      call(announcements: announcements);

  @override
  RemoteAppConfig flags(Map<String, bool> flags) => call(flags: flags);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemoteAppConfig call({
    Object? minVersions = const $CopyWithPlaceholder(),
    Object? updateUrls = const $CopyWithPlaceholder(),
    Object? maintenance = const $CopyWithPlaceholder(),
    Object? announcements = const $CopyWithPlaceholder(),
    Object? flags = const $CopyWithPlaceholder(),
  }) {
    return RemoteAppConfig(
      minVersions:
          minVersions == const $CopyWithPlaceholder() || minVersions == null
          ? _value.minVersions
          // ignore: cast_nullable_to_non_nullable
          : minVersions as RemoteAppConfigMinVersions,
      updateUrls:
          updateUrls == const $CopyWithPlaceholder() || updateUrls == null
          ? _value.updateUrls
          // ignore: cast_nullable_to_non_nullable
          : updateUrls as RemoteAppConfigUpdateUrls,
      maintenance: maintenance == const $CopyWithPlaceholder()
          ? _value.maintenance
          // ignore: cast_nullable_to_non_nullable
          : maintenance as RemoteAppConfigMaintenance?,
      announcements:
          announcements == const $CopyWithPlaceholder() || announcements == null
          ? _value.announcements
          // ignore: cast_nullable_to_non_nullable
          : announcements as List<Announcement>,
      flags: flags == const $CopyWithPlaceholder() || flags == null
          ? _value.flags
          // ignore: cast_nullable_to_non_nullable
          : flags as Map<String, bool>,
    );
  }
}

extension $RemoteAppConfigCopyWith on RemoteAppConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemoteAppConfig.copyWith(...)` or `instanceOfRemoteAppConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemoteAppConfigCWProxy get copyWith => _$RemoteAppConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAppConfig _$RemoteAppConfigFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RemoteAppConfig',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'min_versions',
        'update_urls',
        'maintenance',
        'announcements',
        'flags',
      ],
    );
    final val = RemoteAppConfig(
      minVersions: $checkedConvert(
        'min_versions',
        (v) => RemoteAppConfigMinVersions.fromJson(v as Map<String, dynamic>),
      ),
      updateUrls: $checkedConvert(
        'update_urls',
        (v) => RemoteAppConfigUpdateUrls.fromJson(v as Map<String, dynamic>),
      ),
      maintenance: $checkedConvert(
        'maintenance',
        (v) => v == null
            ? null
            : RemoteAppConfigMaintenance.fromJson(v as Map<String, dynamic>),
      ),
      announcements: $checkedConvert(
        'announcements',
        (v) => (v as List<dynamic>)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      flags: $checkedConvert('flags', (v) => Map<String, bool>.from(v as Map)),
    );
    return val;
  },
  fieldKeyMap: const {
    'minVersions': 'min_versions',
    'updateUrls': 'update_urls',
  },
);

Map<String, dynamic> _$RemoteAppConfigToJson(RemoteAppConfig instance) =>
    <String, dynamic>{
      'min_versions': instance.minVersions.toJson(),
      'update_urls': instance.updateUrls.toJson(),
      'maintenance': instance.maintenance?.toJson(),
      'announcements': instance.announcements.map((e) => e.toJson()).toList(),
      'flags': instance.flags,
    };
