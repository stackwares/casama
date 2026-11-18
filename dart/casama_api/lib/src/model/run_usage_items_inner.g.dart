// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_usage_items_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunUsageItemsInnerCWProxy {
  RunUsageItemsInner kind(String kind);

  RunUsageItemsInner model(String? model);

  RunUsageItemsInner source_(RunUsageItemsInnerSource_Enum source_);

  RunUsageItemsInner billable(bool billable);

  RunUsageItemsInner quantity(num quantity);

  RunUsageItemsInner costUsd(num costUsd);

  RunUsageItemsInner upstreamCostUsd(num? upstreamCostUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunUsageItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunUsageItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  RunUsageItemsInner call({
    String kind,
    String? model,
    RunUsageItemsInnerSource_Enum source_,
    bool billable,
    num quantity,
    num costUsd,
    num? upstreamCostUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunUsageItemsInner.copyWith(...)` or call `instanceOfRunUsageItemsInner.copyWith.fieldName(value)` for a single field.
class _$RunUsageItemsInnerCWProxyImpl implements _$RunUsageItemsInnerCWProxy {
  const _$RunUsageItemsInnerCWProxyImpl(this._value);

  final RunUsageItemsInner _value;

  @override
  RunUsageItemsInner kind(String kind) => call(kind: kind);

  @override
  RunUsageItemsInner model(String? model) => call(model: model);

  @override
  RunUsageItemsInner source_(RunUsageItemsInnerSource_Enum source_) =>
      call(source_: source_);

  @override
  RunUsageItemsInner billable(bool billable) => call(billable: billable);

  @override
  RunUsageItemsInner quantity(num quantity) => call(quantity: quantity);

  @override
  RunUsageItemsInner costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  RunUsageItemsInner upstreamCostUsd(num? upstreamCostUsd) =>
      call(upstreamCostUsd: upstreamCostUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunUsageItemsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunUsageItemsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunUsageItemsInner call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? billable = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? upstreamCostUsd = const $CopyWithPlaceholder(),
  }) {
    return RunUsageItemsInner(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String?,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as RunUsageItemsInnerSource_Enum,
      billable: billable == const $CopyWithPlaceholder() || billable == null
          ? _value.billable
          // ignore: cast_nullable_to_non_nullable
          : billable as bool,
      quantity: quantity == const $CopyWithPlaceholder() || quantity == null
          ? _value.quantity
          // ignore: cast_nullable_to_non_nullable
          : quantity as num,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      upstreamCostUsd: upstreamCostUsd == const $CopyWithPlaceholder()
          ? _value.upstreamCostUsd
          // ignore: cast_nullable_to_non_nullable
          : upstreamCostUsd as num?,
    );
  }
}

extension $RunUsageItemsInnerCopyWith on RunUsageItemsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunUsageItemsInner.copyWith(...)` or `instanceOfRunUsageItemsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunUsageItemsInnerCWProxy get copyWith =>
      _$RunUsageItemsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunUsageItemsInner _$RunUsageItemsInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RunUsageItemsInner',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'kind',
            'model',
            'source',
            'billable',
            'quantity',
            'cost_usd',
          ],
        );
        final val = RunUsageItemsInner(
          kind: $checkedConvert('kind', (v) => v as String),
          model: $checkedConvert('model', (v) => v as String?),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$RunUsageItemsInnerSource_EnumEnumMap, v),
          ),
          billable: $checkedConvert('billable', (v) => v as bool),
          quantity: $checkedConvert('quantity', (v) => v as num),
          costUsd: $checkedConvert('cost_usd', (v) => v as num),
          upstreamCostUsd: $checkedConvert(
            'upstream_cost_usd',
            (v) => v as num?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'source_': 'source',
        'costUsd': 'cost_usd',
        'upstreamCostUsd': 'upstream_cost_usd',
      },
    );

Map<String, dynamic> _$RunUsageItemsInnerToJson(RunUsageItemsInner instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'model': instance.model,
      'source': _$RunUsageItemsInnerSource_EnumEnumMap[instance.source_]!,
      'billable': instance.billable,
      'quantity': instance.quantity,
      'cost_usd': instance.costUsd,
      'upstream_cost_usd': ?instance.upstreamCostUsd,
    };

const _$RunUsageItemsInnerSource_EnumEnumMap = {
  RunUsageItemsInnerSource_Enum.key: 'key',
  RunUsageItemsInnerSource_Enum.chatgptPlan: 'chatgpt_plan',
};
