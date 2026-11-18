// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AnnouncementCWProxy {
  Announcement id(String id);

  Announcement title(String title);

  Announcement body(String body);

  Announcement url(String? url);

  Announcement level(AnnouncementLevelEnum level);

  Announcement startsAt(String? startsAt);

  Announcement endsAt(String? endsAt);

  Announcement platforms(List<AnnouncementPlatformsEnum>? platforms);

  Announcement minVersion(String? minVersion);

  Announcement maxVersion(String? maxVersion);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Announcement(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Announcement(...).copyWith(id: 12, name: "My name")
  /// ```
  Announcement call({
    String id,
    String title,
    String body,
    String? url,
    AnnouncementLevelEnum level,
    String? startsAt,
    String? endsAt,
    List<AnnouncementPlatformsEnum>? platforms,
    String? minVersion,
    String? maxVersion,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAnnouncement.copyWith(...)` or call `instanceOfAnnouncement.copyWith.fieldName(value)` for a single field.
class _$AnnouncementCWProxyImpl implements _$AnnouncementCWProxy {
  const _$AnnouncementCWProxyImpl(this._value);

  final Announcement _value;

  @override
  Announcement id(String id) => call(id: id);

  @override
  Announcement title(String title) => call(title: title);

  @override
  Announcement body(String body) => call(body: body);

  @override
  Announcement url(String? url) => call(url: url);

  @override
  Announcement level(AnnouncementLevelEnum level) => call(level: level);

  @override
  Announcement startsAt(String? startsAt) => call(startsAt: startsAt);

  @override
  Announcement endsAt(String? endsAt) => call(endsAt: endsAt);

  @override
  Announcement platforms(List<AnnouncementPlatformsEnum>? platforms) =>
      call(platforms: platforms);

  @override
  Announcement minVersion(String? minVersion) => call(minVersion: minVersion);

  @override
  Announcement maxVersion(String? maxVersion) => call(maxVersion: maxVersion);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Announcement(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Announcement(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Announcement call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? level = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? platforms = const $CopyWithPlaceholder(),
    Object? minVersion = const $CopyWithPlaceholder(),
    Object? maxVersion = const $CopyWithPlaceholder(),
  }) {
    return Announcement(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      body: body == const $CopyWithPlaceholder() || body == null
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      level: level == const $CopyWithPlaceholder() || level == null
          ? _value.level
          // ignore: cast_nullable_to_non_nullable
          : level as AnnouncementLevelEnum,
      startsAt: startsAt == const $CopyWithPlaceholder()
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as String?,
      endsAt: endsAt == const $CopyWithPlaceholder()
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as String?,
      platforms: platforms == const $CopyWithPlaceholder()
          ? _value.platforms
          // ignore: cast_nullable_to_non_nullable
          : platforms as List<AnnouncementPlatformsEnum>?,
      minVersion: minVersion == const $CopyWithPlaceholder()
          ? _value.minVersion
          // ignore: cast_nullable_to_non_nullable
          : minVersion as String?,
      maxVersion: maxVersion == const $CopyWithPlaceholder()
          ? _value.maxVersion
          // ignore: cast_nullable_to_non_nullable
          : maxVersion as String?,
    );
  }
}

extension $AnnouncementCopyWith on Announcement {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAnnouncement.copyWith(...)` or `instanceOfAnnouncement.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AnnouncementCWProxy get copyWith => _$AnnouncementCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Announcement',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['id', 'title', 'body', 'level']);
        final val = Announcement(
          id: $checkedConvert('id', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String?),
          level: $checkedConvert(
            'level',
            (v) => $enumDecode(_$AnnouncementLevelEnumEnumMap, v),
          ),
          startsAt: $checkedConvert('starts_at', (v) => v as String?),
          endsAt: $checkedConvert('ends_at', (v) => v as String?),
          platforms: $checkedConvert(
            'platforms',
            (v) => (v as List<dynamic>?)
                ?.map((e) => $enumDecode(_$AnnouncementPlatformsEnumEnumMap, e))
                .toList(),
          ),
          minVersion: $checkedConvert('min_version', (v) => v as String?),
          maxVersion: $checkedConvert('max_version', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'startsAt': 'starts_at',
        'endsAt': 'ends_at',
        'minVersion': 'min_version',
        'maxVersion': 'max_version',
      },
    );

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'url': ?instance.url,
      'level': _$AnnouncementLevelEnumEnumMap[instance.level]!,
      'starts_at': ?instance.startsAt,
      'ends_at': ?instance.endsAt,
      'platforms': ?instance.platforms
          ?.map((e) => _$AnnouncementPlatformsEnumEnumMap[e]!)
          .toList(),
      'min_version': ?instance.minVersion,
      'max_version': ?instance.maxVersion,
    };

const _$AnnouncementLevelEnumEnumMap = {
  AnnouncementLevelEnum.info: 'info',
  AnnouncementLevelEnum.warning: 'warning',
};

const _$AnnouncementPlatformsEnumEnumMap = {
  AnnouncementPlatformsEnum.ios: 'ios',
  AnnouncementPlatformsEnum.android: 'android',
  AnnouncementPlatformsEnum.macos: 'macos',
  AnnouncementPlatformsEnum.windows: 'windows',
  AnnouncementPlatformsEnum.linux: 'linux',
  AnnouncementPlatformsEnum.web: 'web',
};
