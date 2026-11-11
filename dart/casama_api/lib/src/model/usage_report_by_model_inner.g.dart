// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report_by_model_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportByModelInnerCWProxy {
  UsageReportByModelInner model(String? model);

  UsageReportByModelInner costUsd(num costUsd);

  UsageReportByModelInner tokensIn(int tokensIn);

  UsageReportByModelInner tokensOut(int tokensOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByModelInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByModelInner(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReportByModelInner call({
    String? model,
    num costUsd,
    int tokensIn,
    int tokensOut,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReportByModelInner.copyWith(...)` or call `instanceOfUsageReportByModelInner.copyWith.fieldName(value)` for a single field.
class _$UsageReportByModelInnerCWProxyImpl
    implements _$UsageReportByModelInnerCWProxy {
  const _$UsageReportByModelInnerCWProxyImpl(this._value);

  final UsageReportByModelInner _value;

  @override
  UsageReportByModelInner model(String? model) => call(model: model);

  @override
  UsageReportByModelInner costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  UsageReportByModelInner tokensIn(int tokensIn) => call(tokensIn: tokensIn);

  @override
  UsageReportByModelInner tokensOut(int tokensOut) =>
      call(tokensOut: tokensOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByModelInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByModelInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReportByModelInner call({
    Object? model = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
  }) {
    return UsageReportByModelInner(
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String?,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      tokensIn: tokensIn == const $CopyWithPlaceholder() || tokensIn == null
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder() || tokensOut == null
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
    );
  }
}

extension $UsageReportByModelInnerCopyWith on UsageReportByModelInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReportByModelInner.copyWith(...)` or `instanceOfUsageReportByModelInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportByModelInnerCWProxy get copyWith =>
      _$UsageReportByModelInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReportByModelInner _$UsageReportByModelInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UsageReportByModelInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['model', 'cost_usd', 'tokens_in', 'tokens_out'],
    );
    final val = UsageReportByModelInner(
      model: $checkedConvert('model', (v) => v as String?),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      tokensIn: $checkedConvert('tokens_in', (v) => (v as num).toInt()),
      tokensOut: $checkedConvert('tokens_out', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'costUsd': 'cost_usd',
    'tokensIn': 'tokens_in',
    'tokensOut': 'tokens_out',
  },
);

Map<String, dynamic> _$UsageReportByModelInnerToJson(
  UsageReportByModelInner instance,
) => <String, dynamic>{
  'model': instance.model,
  'cost_usd': instance.costUsd,
  'tokens_in': instance.tokensIn,
  'tokens_out': instance.tokensOut,
};
