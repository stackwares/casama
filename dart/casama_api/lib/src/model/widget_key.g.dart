// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WidgetKeyCWProxy {
  WidgetKey id(String id);

  WidgetKey orgId(String orgId);

  WidgetKey platform(WidgetKeyPlatformEnum platform);

  WidgetKey label(String? label);

  WidgetKey private(bool private);

  WidgetKey hasPush(bool hasPush);

  WidgetKey lastUsedAt(DateTime? lastUsedAt);

  WidgetKey createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKey(...).copyWith(id: 12, name: "My name")
  /// ```
  WidgetKey call({
    String id,
    String orgId,
    WidgetKeyPlatformEnum platform,
    String? label,
    bool private,
    bool hasPush,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWidgetKey.copyWith(...)` or call `instanceOfWidgetKey.copyWith.fieldName(value)` for a single field.
class _$WidgetKeyCWProxyImpl implements _$WidgetKeyCWProxy {
  const _$WidgetKeyCWProxyImpl(this._value);

  final WidgetKey _value;

  @override
  WidgetKey id(String id) => call(id: id);

  @override
  WidgetKey orgId(String orgId) => call(orgId: orgId);

  @override
  WidgetKey platform(WidgetKeyPlatformEnum platform) =>
      call(platform: platform);

  @override
  WidgetKey label(String? label) => call(label: label);

  @override
  WidgetKey private(bool private) => call(private: private);

  @override
  WidgetKey hasPush(bool hasPush) => call(hasPush: hasPush);

  @override
  WidgetKey lastUsedAt(DateTime? lastUsedAt) => call(lastUsedAt: lastUsedAt);

  @override
  WidgetKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WidgetKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? private = const $CopyWithPlaceholder(),
    Object? hasPush = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return WidgetKey(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as WidgetKeyPlatformEnum,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      private: private == const $CopyWithPlaceholder() || private == null
          ? _value.private
          // ignore: cast_nullable_to_non_nullable
          : private as bool,
      hasPush: hasPush == const $CopyWithPlaceholder() || hasPush == null
          ? _value.hasPush
          // ignore: cast_nullable_to_non_nullable
          : hasPush as bool,
      lastUsedAt: lastUsedAt == const $CopyWithPlaceholder()
          ? _value.lastUsedAt
          // ignore: cast_nullable_to_non_nullable
          : lastUsedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $WidgetKeyCopyWith on WidgetKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWidgetKey.copyWith(...)` or `instanceOfWidgetKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WidgetKeyCWProxy get copyWith => _$WidgetKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetKey _$WidgetKeyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WidgetKey',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'platform',
        'label',
        'private',
        'has_push',
        'last_used_at',
        'created_at',
      ],
    );
    final val = WidgetKey(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      platform: $checkedConvert(
        'platform',
        (v) => $enumDecode(_$WidgetKeyPlatformEnumEnumMap, v),
      ),
      label: $checkedConvert('label', (v) => v as String?),
      private: $checkedConvert('private', (v) => v as bool),
      hasPush: $checkedConvert('has_push', (v) => v as bool),
      lastUsedAt: $checkedConvert(
        'last_used_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'hasPush': 'has_push',
    'lastUsedAt': 'last_used_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$WidgetKeyToJson(WidgetKey instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'platform': _$WidgetKeyPlatformEnumEnumMap[instance.platform]!,
  'label': instance.label,
  'private': instance.private,
  'has_push': instance.hasPush,
  'last_used_at': instance.lastUsedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$WidgetKeyPlatformEnumEnumMap = {
  WidgetKeyPlatformEnum.ios: 'ios',
  WidgetKeyPlatformEnum.android: 'android',
  WidgetKeyPlatformEnum.macos: 'macos',
};
