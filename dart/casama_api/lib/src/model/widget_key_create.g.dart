// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_key_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WidgetKeyCreateCWProxy {
  WidgetKeyCreate orgId(String orgId);

  WidgetKeyCreate platform(WidgetKeyCreatePlatformEnum platform);

  WidgetKeyCreate label(String? label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKeyCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKeyCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  WidgetKeyCreate call({
    String orgId,
    WidgetKeyCreatePlatformEnum platform,
    String? label,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWidgetKeyCreate.copyWith(...)` or call `instanceOfWidgetKeyCreate.copyWith.fieldName(value)` for a single field.
class _$WidgetKeyCreateCWProxyImpl implements _$WidgetKeyCreateCWProxy {
  const _$WidgetKeyCreateCWProxyImpl(this._value);

  final WidgetKeyCreate _value;

  @override
  WidgetKeyCreate orgId(String orgId) => call(orgId: orgId);

  @override
  WidgetKeyCreate platform(WidgetKeyCreatePlatformEnum platform) =>
      call(platform: platform);

  @override
  WidgetKeyCreate label(String? label) => call(label: label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WidgetKeyCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WidgetKeyCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WidgetKeyCreate call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return WidgetKeyCreate(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as WidgetKeyCreatePlatformEnum,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
    );
  }
}

extension $WidgetKeyCreateCopyWith on WidgetKeyCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWidgetKeyCreate.copyWith(...)` or `instanceOfWidgetKeyCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WidgetKeyCreateCWProxy get copyWith => _$WidgetKeyCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetKeyCreate _$WidgetKeyCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WidgetKeyCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['org_id', 'platform']);
      final val = WidgetKeyCreate(
        orgId: $checkedConvert('org_id', (v) => v as String),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$WidgetKeyCreatePlatformEnumEnumMap, v),
        ),
        label: $checkedConvert('label', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$WidgetKeyCreateToJson(WidgetKeyCreate instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'platform': _$WidgetKeyCreatePlatformEnumEnumMap[instance.platform]!,
      'label': ?instance.label,
    };

const _$WidgetKeyCreatePlatformEnumEnumMap = {
  WidgetKeyCreatePlatformEnum.ios: 'ios',
  WidgetKeyCreatePlatformEnum.android: 'android',
  WidgetKeyCreatePlatformEnum.macos: 'macos',
};
