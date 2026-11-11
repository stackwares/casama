// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_usage_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingUsageItemCWProxy {
  BillingUsageItem kind(String kind);

  BillingUsageItem instance(String? instance);

  BillingUsageItem quantity(num quantity);

  BillingUsageItem costUsd(num costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingUsageItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingUsageItem(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingUsageItem call({
    String kind,
    String? instance,
    num quantity,
    num costUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingUsageItem.copyWith(...)` or call `instanceOfBillingUsageItem.copyWith.fieldName(value)` for a single field.
class _$BillingUsageItemCWProxyImpl implements _$BillingUsageItemCWProxy {
  const _$BillingUsageItemCWProxyImpl(this._value);

  final BillingUsageItem _value;

  @override
  BillingUsageItem kind(String kind) => call(kind: kind);

  @override
  BillingUsageItem instance(String? instance) => call(instance: instance);

  @override
  BillingUsageItem quantity(num quantity) => call(quantity: quantity);

  @override
  BillingUsageItem costUsd(num costUsd) => call(costUsd: costUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingUsageItem(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingUsageItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingUsageItem call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? instance = const $CopyWithPlaceholder(),
    Object? quantity = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
  }) {
    return BillingUsageItem(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      instance: instance == const $CopyWithPlaceholder()
          ? _value.instance
          // ignore: cast_nullable_to_non_nullable
          : instance as String?,
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

extension $BillingUsageItemCopyWith on BillingUsageItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingUsageItem.copyWith(...)` or `instanceOfBillingUsageItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingUsageItemCWProxy get copyWith => _$BillingUsageItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingUsageItem _$BillingUsageItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BillingUsageItem', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['kind', 'instance', 'quantity', 'cost_usd'],
      );
      final val = BillingUsageItem(
        kind: $checkedConvert('kind', (v) => v as String),
        instance: $checkedConvert('instance', (v) => v as String?),
        quantity: $checkedConvert('quantity', (v) => v as num),
        costUsd: $checkedConvert('cost_usd', (v) => v as num),
      );
      return val;
    }, fieldKeyMap: const {'costUsd': 'cost_usd'});

Map<String, dynamic> _$BillingUsageItemToJson(BillingUsageItem instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'instance': instance.instance,
      'quantity': instance.quantity,
      'cost_usd': instance.costUsd,
    };
