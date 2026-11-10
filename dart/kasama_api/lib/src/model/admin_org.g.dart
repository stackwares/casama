// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_org.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminOrgCWProxy {
  AdminOrg id(String id);

  AdminOrg name(String name);

  AdminOrg planCode(String? planCode);

  AdminOrg limits(Map<String, num> limits);

  AdminOrg members(int members);

  AdminOrg bots(int bots);

  AdminOrg cost30dUsd(num cost30dUsd);

  AdminOrg suspendedAt(String? suspendedAt);

  AdminOrg suspendedReason(String? suspendedReason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminOrg(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminOrg(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminOrg call({
    String id,
    String name,
    String? planCode,
    Map<String, num> limits,
    int members,
    int bots,
    num cost30dUsd,
    String? suspendedAt,
    String? suspendedReason,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminOrg.copyWith(...)` or call `instanceOfAdminOrg.copyWith.fieldName(value)` for a single field.
class _$AdminOrgCWProxyImpl implements _$AdminOrgCWProxy {
  const _$AdminOrgCWProxyImpl(this._value);

  final AdminOrg _value;

  @override
  AdminOrg id(String id) => call(id: id);

  @override
  AdminOrg name(String name) => call(name: name);

  @override
  AdminOrg planCode(String? planCode) => call(planCode: planCode);

  @override
  AdminOrg limits(Map<String, num> limits) => call(limits: limits);

  @override
  AdminOrg members(int members) => call(members: members);

  @override
  AdminOrg bots(int bots) => call(bots: bots);

  @override
  AdminOrg cost30dUsd(num cost30dUsd) => call(cost30dUsd: cost30dUsd);

  @override
  AdminOrg suspendedAt(String? suspendedAt) => call(suspendedAt: suspendedAt);

  @override
  AdminOrg suspendedReason(String? suspendedReason) =>
      call(suspendedReason: suspendedReason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminOrg(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminOrg(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminOrg call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? limits = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
    Object? bots = const $CopyWithPlaceholder(),
    Object? cost30dUsd = const $CopyWithPlaceholder(),
    Object? suspendedAt = const $CopyWithPlaceholder(),
    Object? suspendedReason = const $CopyWithPlaceholder(),
  }) {
    return AdminOrg(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      planCode: planCode == const $CopyWithPlaceholder()
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String?,
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, num>,
      members: members == const $CopyWithPlaceholder() || members == null
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as int,
      bots: bots == const $CopyWithPlaceholder() || bots == null
          ? _value.bots
          // ignore: cast_nullable_to_non_nullable
          : bots as int,
      cost30dUsd:
          cost30dUsd == const $CopyWithPlaceholder() || cost30dUsd == null
          ? _value.cost30dUsd
          // ignore: cast_nullable_to_non_nullable
          : cost30dUsd as num,
      suspendedAt: suspendedAt == const $CopyWithPlaceholder()
          ? _value.suspendedAt
          // ignore: cast_nullable_to_non_nullable
          : suspendedAt as String?,
      suspendedReason: suspendedReason == const $CopyWithPlaceholder()
          ? _value.suspendedReason
          // ignore: cast_nullable_to_non_nullable
          : suspendedReason as String?,
    );
  }
}

extension $AdminOrgCopyWith on AdminOrg {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminOrg.copyWith(...)` or `instanceOfAdminOrg.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminOrgCWProxy get copyWith => _$AdminOrgCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOrg _$AdminOrgFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminOrg',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'plan_code',
        'limits',
        'members',
        'bots',
        'cost_30d_usd',
      ],
    );
    final val = AdminOrg(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      planCode: $checkedConvert('plan_code', (v) => v as String?),
      limits: $checkedConvert('limits', (v) => Map<String, num>.from(v as Map)),
      members: $checkedConvert('members', (v) => (v as num).toInt()),
      bots: $checkedConvert('bots', (v) => (v as num).toInt()),
      cost30dUsd: $checkedConvert('cost_30d_usd', (v) => v as num),
      suspendedAt: $checkedConvert('suspended_at', (v) => v as String?),
      suspendedReason: $checkedConvert('suspended_reason', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'planCode': 'plan_code',
    'cost30dUsd': 'cost_30d_usd',
    'suspendedAt': 'suspended_at',
    'suspendedReason': 'suspended_reason',
  },
);

Map<String, dynamic> _$AdminOrgToJson(AdminOrg instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'plan_code': instance.planCode,
  'limits': instance.limits,
  'members': instance.members,
  'bots': instance.bots,
  'cost_30d_usd': instance.cost30dUsd,
  'suspended_at': ?instance.suspendedAt,
  'suspended_reason': ?instance.suspendedReason,
};
