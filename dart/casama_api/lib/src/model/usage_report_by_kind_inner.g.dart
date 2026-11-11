// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report_by_kind_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportByKindInnerCWProxy {
  UsageReportByKindInner kind(String kind);

  UsageReportByKindInner quantity(num quantity);

  UsageReportByKindInner costUsd(num costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByKindInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByKindInner(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReportByKindInner call({String kind, num quantity, num costUsd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReportByKindInner.copyWith(...)` or call `instanceOfUsageReportByKindInner.copyWith.fieldName(value)` for a single field.
class _$UsageReportByKindInnerCWProxyImpl
    implements _$UsageReportByKindInnerCWProxy {
  const _$UsageReportByKindInnerCWProxyImpl(this._value);

  final UsageReportByKindInner _value;

  @override
  UsageReportByKindInner kind(String kind) => call(kind: kind);

  @override
  UsageReportByKindInner quantity(num quantity) => call(quantity: quantity);

  @override
  UsageReportByKindInner costUsd(num costUsd) => call(costUsd: costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByKindInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByKindInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReportByKindInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
  }) {
    return UsageReportByKindInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      quantity: quantity == const $CopyWithPlaceholder() || quantity == null
          ? _value.quantity
          // ignore: cast_nullable_to_non_nullable
          : quantity as num,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
    );
  }
}

extension $UsageReportByKindInnerCopyWith on UsageReportByKindInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReportByKindInner.copyWith(...)` or `instanceOfUsageReportByKindInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportByKindInnerCWProxy get copyWith =>
      _$UsageReportByKindInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReportByKindInner _$UsageReportByKindInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UsageReportByKindInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['kind', 'quantity', 'cost_usd']);
  final val = UsageReportByKindInner(
    kind: $checkedConvert('kind', (v) => v as String),
    quantity: $checkedConvert('quantity', (v) => v as num),
    costUsd: $checkedConvert('cost_usd', (v) => v as num),
  );
  return val;
}, fieldKeyMap: const {'costUsd': 'cost_usd'});

Map<String, dynamic> _$UsageReportByKindInnerToJson(
  UsageReportByKindInner instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'quantity': instance.quantity,
  'cost_usd': instance.costUsd,
};
