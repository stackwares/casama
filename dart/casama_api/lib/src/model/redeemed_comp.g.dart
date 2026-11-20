// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeemed_comp.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedeemedCompCWProxy {
  RedeemedComp planCode(String planCode);

  RedeemedComp planName(String planName);

  RedeemedComp endsAt(DateTime endsAt);

  RedeemedComp orgId(String orgId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemedComp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemedComp(...).copyWith(id: 12, name: "My name")
  /// ```
  RedeemedComp call({
    String planCode,
    String planName,
    DateTime endsAt,
    String orgId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedeemedComp.copyWith(...)` or call `instanceOfRedeemedComp.copyWith.fieldName(value)` for a single field.
class _$RedeemedCompCWProxyImpl implements _$RedeemedCompCWProxy {
  const _$RedeemedCompCWProxyImpl(this._value);

  final RedeemedComp _value;

  @override
  RedeemedComp planCode(String planCode) => call(planCode: planCode);

  @override
  RedeemedComp planName(String planName) => call(planName: planName);

  @override
  RedeemedComp endsAt(DateTime endsAt) => call(endsAt: endsAt);

  @override
  RedeemedComp orgId(String orgId) => call(orgId: orgId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedeemedComp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedeemedComp(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedeemedComp call({
    Object? planCode = const $CopyWithPlaceholder(),
    Object? planName = const $CopyWithPlaceholder(),
    Object? endsAt = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
  }) {
    return RedeemedComp(
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      planName: planName == const $CopyWithPlaceholder() || planName == null
          ? _value.planName
          // ignore: cast_nullable_to_non_nullable
          : planName as String,
      endsAt: endsAt == const $CopyWithPlaceholder() || endsAt == null
          ? _value.endsAt
          // ignore: cast_nullable_to_non_nullable
          : endsAt as DateTime,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
    );
  }
}

extension $RedeemedCompCopyWith on RedeemedComp {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedeemedComp.copyWith(...)` or `instanceOfRedeemedComp.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedeemedCompCWProxy get copyWith => _$RedeemedCompCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemedComp _$RedeemedCompFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RedeemedComp',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['plan_code', 'plan_name', 'ends_at', 'org_id'],
        );
        final val = RedeemedComp(
          planCode: $checkedConvert('plan_code', (v) => v as String),
          planName: $checkedConvert('plan_name', (v) => v as String),
          endsAt: $checkedConvert(
            'ends_at',
            (v) => DateTime.parse(v as String),
          ),
          orgId: $checkedConvert('org_id', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'planCode': 'plan_code',
        'planName': 'plan_name',
        'endsAt': 'ends_at',
        'orgId': 'org_id',
      },
    );

Map<String, dynamic> _$RedeemedCompToJson(RedeemedComp instance) =>
    <String, dynamic>{
      'plan_code': instance.planCode,
      'plan_name': instance.planName,
      'ends_at': instance.endsAt.toIso8601String(),
      'org_id': instance.orgId,
    };
