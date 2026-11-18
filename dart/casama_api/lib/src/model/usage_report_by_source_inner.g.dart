// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report_by_source_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportBySourceInnerCWProxy {
  UsageReportBySourceInner source_(UsageSource source_);

  UsageReportBySourceInner costUsd(num costUsd);

  UsageReportBySourceInner runs(int runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportBySourceInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportBySourceInner(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReportBySourceInner call({UsageSource source_, num costUsd, int runs});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReportBySourceInner.copyWith(...)` or call `instanceOfUsageReportBySourceInner.copyWith.fieldName(value)` for a single field.
class _$UsageReportBySourceInnerCWProxyImpl
    implements _$UsageReportBySourceInnerCWProxy {
  const _$UsageReportBySourceInnerCWProxyImpl(this._value);

  final UsageReportBySourceInner _value;

  @override
  UsageReportBySourceInner source_(UsageSource source_) =>
      call(source_: source_);

  @override
  UsageReportBySourceInner costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  UsageReportBySourceInner runs(int runs) => call(runs: runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportBySourceInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportBySourceInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReportBySourceInner call({
    Object? source_ = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? runs = const $CopyWithPlaceholder(),
  }) {
    return UsageReportBySourceInner(
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as UsageSource,
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

extension $UsageReportBySourceInnerCopyWith on UsageReportBySourceInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReportBySourceInner.copyWith(...)` or `instanceOfUsageReportBySourceInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportBySourceInnerCWProxy get copyWith =>
      _$UsageReportBySourceInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReportBySourceInner _$UsageReportBySourceInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UsageReportBySourceInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['source', 'cost_usd', 'runs']);
  final val = UsageReportBySourceInner(
    source_: $checkedConvert(
      'source',
      (v) => $enumDecode(_$UsageSourceEnumMap, v),
    ),
    costUsd: $checkedConvert('cost_usd', (v) => v as num),
    runs: $checkedConvert('runs', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'source_': 'source', 'costUsd': 'cost_usd'});

Map<String, dynamic> _$UsageReportBySourceInnerToJson(
  UsageReportBySourceInner instance,
) => <String, dynamic>{
  'source': _$UsageSourceEnumMap[instance.source_]!,
  'cost_usd': instance.costUsd,
  'runs': instance.runs,
};

const _$UsageSourceEnumMap = {
  UsageSource.chat: 'chat',
  UsageSource.chatApp: 'chat_app',
  UsageSource.routine: 'routine',
  UsageSource.api: 'api',
  UsageSource.other: 'other',
};
