// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_search_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainSearchResultCWProxy {
  DomainSearchResult name(String name);

  DomainSearchResult available(bool available);

  DomainSearchResult reason(String? reason);

  DomainSearchResult priceUsd(num? priceUsd);

  DomainSearchResult renewPriceUsd(num? renewPriceUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainSearchResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainSearchResult(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainSearchResult call({
    String name,
    bool available,
    String? reason,
    num? priceUsd,
    num? renewPriceUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainSearchResult.copyWith(...)` or call `instanceOfDomainSearchResult.copyWith.fieldName(value)` for a single field.
class _$DomainSearchResultCWProxyImpl implements _$DomainSearchResultCWProxy {
  const _$DomainSearchResultCWProxyImpl(this._value);

  final DomainSearchResult _value;

  @override
  DomainSearchResult name(String name) => call(name: name);

  @override
  DomainSearchResult available(bool available) => call(available: available);

  @override
  DomainSearchResult reason(String? reason) => call(reason: reason);

  @override
  DomainSearchResult priceUsd(num? priceUsd) => call(priceUsd: priceUsd);

  @override
  DomainSearchResult renewPriceUsd(num? renewPriceUsd) =>
      call(renewPriceUsd: renewPriceUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainSearchResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainSearchResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainSearchResult call({
    Object? name = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? priceUsd = const $CopyWithPlaceholder(),
    Object? renewPriceUsd = const $CopyWithPlaceholder(),
  }) {
    return DomainSearchResult(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      priceUsd: priceUsd == const $CopyWithPlaceholder()
          ? _value.priceUsd
          // ignore: cast_nullable_to_non_nullable
          : priceUsd as num?,
      renewPriceUsd: renewPriceUsd == const $CopyWithPlaceholder()
          ? _value.renewPriceUsd
          // ignore: cast_nullable_to_non_nullable
          : renewPriceUsd as num?,
    );
  }
}

extension $DomainSearchResultCopyWith on DomainSearchResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainSearchResult.copyWith(...)` or `instanceOfDomainSearchResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainSearchResultCWProxy get copyWith =>
      _$DomainSearchResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainSearchResult _$DomainSearchResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DomainSearchResult',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'name',
            'available',
            'reason',
            'price_usd',
            'renew_price_usd',
          ],
        );
        final val = DomainSearchResult(
          name: $checkedConvert('name', (v) => v as String),
          available: $checkedConvert('available', (v) => v as bool),
          reason: $checkedConvert('reason', (v) => v as String?),
          priceUsd: $checkedConvert('price_usd', (v) => v as num?),
          renewPriceUsd: $checkedConvert('renew_price_usd', (v) => v as num?),
        );
        return val;
      },
      fieldKeyMap: const {
        'priceUsd': 'price_usd',
        'renewPriceUsd': 'renew_price_usd',
      },
    );

Map<String, dynamic> _$DomainSearchResultToJson(DomainSearchResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'available': instance.available,
      'reason': instance.reason,
      'price_usd': instance.priceUsd,
      'renew_price_usd': instance.renewPriceUsd,
    };
