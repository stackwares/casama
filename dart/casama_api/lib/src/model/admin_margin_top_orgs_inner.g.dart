// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_margin_top_orgs_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMarginTopOrgsInnerCWProxy {
  AdminMarginTopOrgsInner orgId(String orgId);

  AdminMarginTopOrgsInner name(String name);

  AdminMarginTopOrgsInner planCode(String? planCode);

  AdminMarginTopOrgsInner chargedUsd(num chargedUsd);

  AdminMarginTopOrgsInner chargedTrackedUsd(num chargedTrackedUsd);

  AdminMarginTopOrgsInner upstreamUsd(num upstreamUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMarginTopOrgsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMarginTopOrgsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMarginTopOrgsInner call({
    String orgId,
    String name,
    String? planCode,
    num chargedUsd,
    num chargedTrackedUsd,
    num upstreamUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMarginTopOrgsInner.copyWith(...)` or call `instanceOfAdminMarginTopOrgsInner.copyWith.fieldName(value)` for a single field.
class _$AdminMarginTopOrgsInnerCWProxyImpl
    implements _$AdminMarginTopOrgsInnerCWProxy {
  const _$AdminMarginTopOrgsInnerCWProxyImpl(this._value);

  final AdminMarginTopOrgsInner _value;

  @override
  AdminMarginTopOrgsInner orgId(String orgId) => call(orgId: orgId);

  @override
  AdminMarginTopOrgsInner name(String name) => call(name: name);

  @override
  AdminMarginTopOrgsInner planCode(String? planCode) =>
      call(planCode: planCode);

  @override
  AdminMarginTopOrgsInner chargedUsd(num chargedUsd) =>
      call(chargedUsd: chargedUsd);

  @override
  AdminMarginTopOrgsInner chargedTrackedUsd(num chargedTrackedUsd) =>
      call(chargedTrackedUsd: chargedTrackedUsd);

  @override
  AdminMarginTopOrgsInner upstreamUsd(num upstreamUsd) =>
      call(upstreamUsd: upstreamUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMarginTopOrgsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMarginTopOrgsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMarginTopOrgsInner call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? chargedUsd = const $CopyWithPlaceholder(),
    Object? chargedTrackedUsd = const $CopyWithPlaceholder(),
    Object? upstreamUsd = const $CopyWithPlaceholder(),
  }) {
    return AdminMarginTopOrgsInner(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      planCode: planCode == const $CopyWithPlaceholder()
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String?,
      chargedUsd:
          chargedUsd == const $CopyWithPlaceholder() || chargedUsd == null
          ? _value.chargedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedUsd as num,
      chargedTrackedUsd:
          chargedTrackedUsd == const $CopyWithPlaceholder() ||
              chargedTrackedUsd == null
          ? _value.chargedTrackedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedTrackedUsd as num,
      upstreamUsd:
          upstreamUsd == const $CopyWithPlaceholder() || upstreamUsd == null
          ? _value.upstreamUsd
          // ignore: cast_nullable_to_non_nullable
          : upstreamUsd as num,
    );
  }
}

extension $AdminMarginTopOrgsInnerCopyWith on AdminMarginTopOrgsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMarginTopOrgsInner.copyWith(...)` or `instanceOfAdminMarginTopOrgsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMarginTopOrgsInnerCWProxy get copyWith =>
      _$AdminMarginTopOrgsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMarginTopOrgsInner _$AdminMarginTopOrgsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminMarginTopOrgsInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'org_id',
        'name',
        'plan_code',
        'charged_usd',
        'charged_tracked_usd',
        'upstream_usd',
      ],
    );
    final val = AdminMarginTopOrgsInner(
      orgId: $checkedConvert('org_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      planCode: $checkedConvert('plan_code', (v) => v as String?),
      chargedUsd: $checkedConvert('charged_usd', (v) => v as num),
      chargedTrackedUsd: $checkedConvert(
        'charged_tracked_usd',
        (v) => v as num,
      ),
      upstreamUsd: $checkedConvert('upstream_usd', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'planCode': 'plan_code',
    'chargedUsd': 'charged_usd',
    'chargedTrackedUsd': 'charged_tracked_usd',
    'upstreamUsd': 'upstream_usd',
  },
);

Map<String, dynamic> _$AdminMarginTopOrgsInnerToJson(
  AdminMarginTopOrgsInner instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'name': instance.name,
  'plan_code': instance.planCode,
  'charged_usd': instance.chargedUsd,
  'charged_tracked_usd': instance.chargedTrackedUsd,
  'upstream_usd': instance.upstreamUsd,
};
