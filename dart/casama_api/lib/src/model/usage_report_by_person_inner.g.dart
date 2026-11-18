// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report_by_person_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportByPersonInnerCWProxy {
  UsageReportByPersonInner userId(String? userId);

  UsageReportByPersonInner name(String? name);

  UsageReportByPersonInner costUsd(num costUsd);

  UsageReportByPersonInner runs(int runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByPersonInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByPersonInner(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReportByPersonInner call({
    String? userId,
    String? name,
    num costUsd,
    int runs,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReportByPersonInner.copyWith(...)` or call `instanceOfUsageReportByPersonInner.copyWith.fieldName(value)` for a single field.
class _$UsageReportByPersonInnerCWProxyImpl
    implements _$UsageReportByPersonInnerCWProxy {
  const _$UsageReportByPersonInnerCWProxyImpl(this._value);

  final UsageReportByPersonInner _value;

  @override
  UsageReportByPersonInner userId(String? userId) => call(userId: userId);

  @override
  UsageReportByPersonInner name(String? name) => call(name: name);

  @override
  UsageReportByPersonInner costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  UsageReportByPersonInner runs(int runs) => call(runs: runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByPersonInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByPersonInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReportByPersonInner call({
    Object? userId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? runs = const $CopyWithPlaceholder(),
  }) {
    return UsageReportByPersonInner(
      userId: userId == const $CopyWithPlaceholder()
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      runs: runs == const $CopyWithPlaceholder() || runs == null
          ? _value.runs
          // ignore: cast_nullable_to_non_nullable
          : runs as int,
    );
  }
}

extension $UsageReportByPersonInnerCopyWith on UsageReportByPersonInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReportByPersonInner.copyWith(...)` or `instanceOfUsageReportByPersonInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportByPersonInnerCWProxy get copyWith =>
      _$UsageReportByPersonInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReportByPersonInner _$UsageReportByPersonInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UsageReportByPersonInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['user_id', 'name', 'cost_usd', 'runs']);
  final val = UsageReportByPersonInner(
    userId: $checkedConvert('user_id', (v) => v as String?),
    name: $checkedConvert('name', (v) => v as String?),
    costUsd: $checkedConvert('cost_usd', (v) => v as num),
    runs: $checkedConvert('runs', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'userId': 'user_id', 'costUsd': 'cost_usd'});

Map<String, dynamic> _$UsageReportByPersonInnerToJson(
  UsageReportByPersonInner instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
  'cost_usd': instance.costUsd,
  'runs': instance.runs,
};
