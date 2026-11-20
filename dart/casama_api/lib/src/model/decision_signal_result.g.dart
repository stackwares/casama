// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_signal_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DecisionSignalResultCWProxy {
  DecisionSignalResult use(String use);

  DecisionSignalResult signal(String signal);

  DecisionSignalResult model(String model);

  DecisionSignalResult rows(int rows);

  DecisionSignalResult answered(int answered);

  DecisionSignalResult errors(int errors);

  DecisionSignalResult latencyP50Ms(num latencyP50Ms);

  DecisionSignalResult latencyP95Ms(num latencyP95Ms);

  DecisionSignalResult costUsd(num costUsd);

  DecisionSignalResult labelled(int labelled);

  DecisionSignalResult positives(int positives);

  DecisionSignalResult thresholds(
    List<DecisionSignalResultThresholdsInner> thresholds,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSignalResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSignalResult(...).copyWith(id: 12, name: "My name")
  /// ```
  DecisionSignalResult call({
    String use,
    String signal,
    String model,
    int rows,
    int answered,
    int errors,
    num latencyP50Ms,
    num latencyP95Ms,
    num costUsd,
    int labelled,
    int positives,
    List<DecisionSignalResultThresholdsInner> thresholds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDecisionSignalResult.copyWith(...)` or call `instanceOfDecisionSignalResult.copyWith.fieldName(value)` for a single field.
class _$DecisionSignalResultCWProxyImpl
    implements _$DecisionSignalResultCWProxy {
  const _$DecisionSignalResultCWProxyImpl(this._value);

  final DecisionSignalResult _value;

  @override
  DecisionSignalResult use(String use) => call(use: use);

  @override
  DecisionSignalResult signal(String signal) => call(signal: signal);

  @override
  DecisionSignalResult model(String model) => call(model: model);

  @override
  DecisionSignalResult rows(int rows) => call(rows: rows);

  @override
  DecisionSignalResult answered(int answered) => call(answered: answered);

  @override
  DecisionSignalResult errors(int errors) => call(errors: errors);

  @override
  DecisionSignalResult latencyP50Ms(num latencyP50Ms) =>
      call(latencyP50Ms: latencyP50Ms);

  @override
  DecisionSignalResult latencyP95Ms(num latencyP95Ms) =>
      call(latencyP95Ms: latencyP95Ms);

  @override
  DecisionSignalResult costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  DecisionSignalResult labelled(int labelled) => call(labelled: labelled);

  @override
  DecisionSignalResult positives(int positives) => call(positives: positives);

  @override
  DecisionSignalResult thresholds(
    List<DecisionSignalResultThresholdsInner> thresholds,
  ) => call(thresholds: thresholds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DecisionSignalResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DecisionSignalResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DecisionSignalResult call({
    Object? use = const $CopyWithPlaceholder(),
    Object? signal = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? rows = const $CopyWithPlaceholder(),
    Object? answered = const $CopyWithPlaceholder(),
    Object? errors = const $CopyWithPlaceholder(),
    Object? latencyP50Ms = const $CopyWithPlaceholder(),
    Object? latencyP95Ms = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? labelled = const $CopyWithPlaceholder(),
    Object? positives = const $CopyWithPlaceholder(),
    Object? thresholds = const $CopyWithPlaceholder(),
  }) {
    return DecisionSignalResult(
      use: use == const $CopyWithPlaceholder() || use == null
          ? _value.use
          // ignore: cast_nullable_to_non_nullable
          : use as String,
      signal: signal == const $CopyWithPlaceholder() || signal == null
          ? _value.signal
          // ignore: cast_nullable_to_non_nullable
          : signal as String,
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      rows: rows == const $CopyWithPlaceholder() || rows == null
          ? _value.rows
          // ignore: cast_nullable_to_non_nullable
          : rows as int,
      answered: answered == const $CopyWithPlaceholder() || answered == null
          ? _value.answered
          // ignore: cast_nullable_to_non_nullable
          : answered as int,
      errors: errors == const $CopyWithPlaceholder() || errors == null
          ? _value.errors
          // ignore: cast_nullable_to_non_nullable
          : errors as int,
      latencyP50Ms:
          latencyP50Ms == const $CopyWithPlaceholder() || latencyP50Ms == null
          ? _value.latencyP50Ms
          // ignore: cast_nullable_to_non_nullable
          : latencyP50Ms as num,
      latencyP95Ms:
          latencyP95Ms == const $CopyWithPlaceholder() || latencyP95Ms == null
          ? _value.latencyP95Ms
          // ignore: cast_nullable_to_non_nullable
          : latencyP95Ms as num,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      labelled: labelled == const $CopyWithPlaceholder() || labelled == null
          ? _value.labelled
          // ignore: cast_nullable_to_non_nullable
          : labelled as int,
      positives: positives == const $CopyWithPlaceholder() || positives == null
          ? _value.positives
          // ignore: cast_nullable_to_non_nullable
          : positives as int,
      thresholds:
          thresholds == const $CopyWithPlaceholder() || thresholds == null
          ? _value.thresholds
          // ignore: cast_nullable_to_non_nullable
          : thresholds as List<DecisionSignalResultThresholdsInner>,
    );
  }
}

extension $DecisionSignalResultCopyWith on DecisionSignalResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDecisionSignalResult.copyWith(...)` or `instanceOfDecisionSignalResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DecisionSignalResultCWProxy get copyWith =>
      _$DecisionSignalResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DecisionSignalResult _$DecisionSignalResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DecisionSignalResult',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'use',
        'signal',
        'model',
        'rows',
        'answered',
        'errors',
        'latency_p50_ms',
        'latency_p95_ms',
        'cost_usd',
        'labelled',
        'positives',
        'thresholds',
      ],
    );
    final val = DecisionSignalResult(
      use: $checkedConvert('use', (v) => v as String),
      signal: $checkedConvert('signal', (v) => v as String),
      model: $checkedConvert('model', (v) => v as String),
      rows: $checkedConvert('rows', (v) => (v as num).toInt()),
      answered: $checkedConvert('answered', (v) => (v as num).toInt()),
      errors: $checkedConvert('errors', (v) => (v as num).toInt()),
      latencyP50Ms: $checkedConvert('latency_p50_ms', (v) => v as num),
      latencyP95Ms: $checkedConvert('latency_p95_ms', (v) => v as num),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      labelled: $checkedConvert('labelled', (v) => (v as num).toInt()),
      positives: $checkedConvert('positives', (v) => (v as num).toInt()),
      thresholds: $checkedConvert(
        'thresholds',
        (v) => (v as List<dynamic>)
            .map(
              (e) => DecisionSignalResultThresholdsInner.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'latencyP50Ms': 'latency_p50_ms',
    'latencyP95Ms': 'latency_p95_ms',
    'costUsd': 'cost_usd',
  },
);

Map<String, dynamic> _$DecisionSignalResultToJson(
  DecisionSignalResult instance,
) => <String, dynamic>{
  'use': instance.use,
  'signal': instance.signal,
  'model': instance.model,
  'rows': instance.rows,
  'answered': instance.answered,
  'errors': instance.errors,
  'latency_p50_ms': instance.latencyP50Ms,
  'latency_p95_ms': instance.latencyP95Ms,
  'cost_usd': instance.costUsd,
  'labelled': instance.labelled,
  'positives': instance.positives,
  'thresholds': instance.thresholds.map((e) => e.toJson()).toList(),
};
