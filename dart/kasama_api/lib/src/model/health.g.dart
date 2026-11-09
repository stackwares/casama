// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HealthCWProxy {
  Health status(HealthStatusEnum status);

  Health checks(Map<String, String>? checks);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Health(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Health(...).copyWith(id: 12, name: "My name")
  /// ````
  Health call({HealthStatusEnum status, Map<String, String>? checks});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfHealth.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfHealth.copyWith.fieldName(...)`
class _$HealthCWProxyImpl implements _$HealthCWProxy {
  const _$HealthCWProxyImpl(this._value);

  final Health _value;

  @override
  Health status(HealthStatusEnum status) => this(status: status);

  @override
  Health checks(Map<String, String>? checks) => this(checks: checks);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Health(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Health(...).copyWith(id: 12, name: "My name")
  /// ````
  Health call({
    Object? status = const $CopyWithPlaceholder(),
    Object? checks = const $CopyWithPlaceholder(),
  }) {
    return Health(
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as HealthStatusEnum,
      checks: checks == const $CopyWithPlaceholder()
          ? _value.checks
          // ignore: cast_nullable_to_non_nullable
          : checks as Map<String, String>?,
    );
  }
}

extension $HealthCopyWith on Health {
  /// Returns a callable class that can be used as follows: `instanceOfHealth.copyWith(...)` or like so:`instanceOfHealth.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HealthCWProxy get copyWith => _$HealthCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Health', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status']);
      final val = Health(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$HealthStatusEnumEnumMap, v),
        ),
        checks: $checkedConvert(
          'checks',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': _$HealthStatusEnumEnumMap[instance.status]!,
  'checks': ?instance.checks,
};

const _$HealthStatusEnumEnumMap = {
  HealthStatusEnum.ok: 'ok',
  HealthStatusEnum.degraded: 'degraded',
};
