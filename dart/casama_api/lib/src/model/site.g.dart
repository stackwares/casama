// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteCWProxy {
  Site pageId(String pageId);

  Site title(String title);

  Site label(String? label);

  Site addressUrl(String? addressUrl);

  Site url(String? url);

  Site live(bool live);

  Site indexable(bool indexable);

  Site badge(bool badge);

  Site canIndex(bool canIndex);

  Site hosts(List<SiteHost> hosts);

  Site createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Site(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Site(...).copyWith(id: 12, name: "My name")
  /// ```
  Site call({
    String pageId,
    String title,
    String? label,
    String? addressUrl,
    String? url,
    bool live,
    bool indexable,
    bool badge,
    bool canIndex,
    List<SiteHost> hosts,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSite.copyWith(...)` or call `instanceOfSite.copyWith.fieldName(value)` for a single field.
class _$SiteCWProxyImpl implements _$SiteCWProxy {
  const _$SiteCWProxyImpl(this._value);

  final Site _value;

  @override
  Site pageId(String pageId) => call(pageId: pageId);

  @override
  Site title(String title) => call(title: title);

  @override
  Site label(String? label) => call(label: label);

  @override
  Site addressUrl(String? addressUrl) => call(addressUrl: addressUrl);

  @override
  Site url(String? url) => call(url: url);

  @override
  Site live(bool live) => call(live: live);

  @override
  Site indexable(bool indexable) => call(indexable: indexable);

  @override
  Site badge(bool badge) => call(badge: badge);

  @override
  Site canIndex(bool canIndex) => call(canIndex: canIndex);

  @override
  Site hosts(List<SiteHost> hosts) => call(hosts: hosts);

  @override
  Site createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Site(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Site(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Site call({
    Object? pageId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? addressUrl = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? live = const $CopyWithPlaceholder(),
    Object? indexable = const $CopyWithPlaceholder(),
    Object? badge = const $CopyWithPlaceholder(),
    Object? canIndex = const $CopyWithPlaceholder(),
    Object? hosts = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Site(
      pageId: pageId == const $CopyWithPlaceholder() || pageId == null
          ? _value.pageId
          // ignore: cast_nullable_to_non_nullable
          : pageId as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      addressUrl: addressUrl == const $CopyWithPlaceholder()
          ? _value.addressUrl
          // ignore: cast_nullable_to_non_nullable
          : addressUrl as String?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
      live: live == const $CopyWithPlaceholder() || live == null
          ? _value.live
          // ignore: cast_nullable_to_non_nullable
          : live as bool,
      indexable: indexable == const $CopyWithPlaceholder() || indexable == null
          ? _value.indexable
          // ignore: cast_nullable_to_non_nullable
          : indexable as bool,
      badge: badge == const $CopyWithPlaceholder() || badge == null
          ? _value.badge
          // ignore: cast_nullable_to_non_nullable
          : badge as bool,
      canIndex: canIndex == const $CopyWithPlaceholder() || canIndex == null
          ? _value.canIndex
          // ignore: cast_nullable_to_non_nullable
          : canIndex as bool,
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as List<SiteHost>,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SiteCopyWith on Site {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSite.copyWith(...)` or `instanceOfSite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteCWProxy get copyWith => _$SiteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Site _$SiteFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Site',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'page_id',
        'title',
        'label',
        'address_url',
        'url',
        'live',
        'indexable',
        'badge',
        'can_index',
        'hosts',
        'created_at',
      ],
    );
    final val = Site(
      pageId: $checkedConvert('page_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String?),
      addressUrl: $checkedConvert('address_url', (v) => v as String?),
      url: $checkedConvert('url', (v) => v as String?),
      live: $checkedConvert('live', (v) => v as bool),
      indexable: $checkedConvert('indexable', (v) => v as bool),
      badge: $checkedConvert('badge', (v) => v as bool),
      canIndex: $checkedConvert('can_index', (v) => v as bool),
      hosts: $checkedConvert(
        'hosts',
        (v) => (v as List<dynamic>)
            .map((e) => SiteHost.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'pageId': 'page_id',
    'addressUrl': 'address_url',
    'canIndex': 'can_index',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$SiteToJson(Site instance) => <String, dynamic>{
  'page_id': instance.pageId,
  'title': instance.title,
  'label': instance.label,
  'address_url': instance.addressUrl,
  'url': instance.url,
  'live': instance.live,
  'indexable': instance.indexable,
  'badge': instance.badge,
  'can_index': instance.canIndex,
  'hosts': instance.hosts.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt.toIso8601String(),
};
