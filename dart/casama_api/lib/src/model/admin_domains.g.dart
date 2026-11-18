// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_domains.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminDomainsCWProxy {
  AdminDomains counts(AdminDomainsCounts counts);

  AdminDomains balanceUsd(num? balanceUsd);

  AdminDomains orders(List<AdminDomainOrder> orders);

  AdminDomains domains(List<AdminDomain> domains);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomains(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomains(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminDomains call({
    AdminDomainsCounts counts,
    num? balanceUsd,
    List<AdminDomainOrder> orders,
    List<AdminDomain> domains,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminDomains.copyWith(...)` or call `instanceOfAdminDomains.copyWith.fieldName(value)` for a single field.
class _$AdminDomainsCWProxyImpl implements _$AdminDomainsCWProxy {
  const _$AdminDomainsCWProxyImpl(this._value);

  final AdminDomains _value;

  @override
  AdminDomains counts(AdminDomainsCounts counts) => call(counts: counts);

  @override
  AdminDomains balanceUsd(num? balanceUsd) => call(balanceUsd: balanceUsd);

  @override
  AdminDomains orders(List<AdminDomainOrder> orders) => call(orders: orders);

  @override
  AdminDomains domains(List<AdminDomain> domains) => call(domains: domains);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminDomains(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminDomains(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminDomains call({
    Object? counts = const $CopyWithPlaceholder(),
    Object? balanceUsd = const $CopyWithPlaceholder(),
    Object? orders = const $CopyWithPlaceholder(),
    Object? domains = const $CopyWithPlaceholder(),
  }) {
    return AdminDomains(
      counts: counts == const $CopyWithPlaceholder() || counts == null
          ? _value.counts
          // ignore: cast_nullable_to_non_nullable
          : counts as AdminDomainsCounts,
      balanceUsd: balanceUsd == const $CopyWithPlaceholder()
          ? _value.balanceUsd
          // ignore: cast_nullable_to_non_nullable
          : balanceUsd as num?,
      orders: orders == const $CopyWithPlaceholder() || orders == null
          ? _value.orders
          // ignore: cast_nullable_to_non_nullable
          : orders as List<AdminDomainOrder>,
      domains: domains == const $CopyWithPlaceholder() || domains == null
          ? _value.domains
          // ignore: cast_nullable_to_non_nullable
          : domains as List<AdminDomain>,
    );
  }
}

extension $AdminDomainsCopyWith on AdminDomains {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminDomains.copyWith(...)` or `instanceOfAdminDomains.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminDomainsCWProxy get copyWith => _$AdminDomainsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDomains _$AdminDomainsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminDomains', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['counts', 'balance_usd', 'orders', 'domains'],
      );
      final val = AdminDomains(
        counts: $checkedConvert(
          'counts',
          (v) => AdminDomainsCounts.fromJson(v as Map<String, dynamic>),
        ),
        balanceUsd: $checkedConvert('balance_usd', (v) => v as num?),
        orders: $checkedConvert(
          'orders',
          (v) => (v as List<dynamic>)
              .map((e) => AdminDomainOrder.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        domains: $checkedConvert(
          'domains',
          (v) => (v as List<dynamic>)
              .map((e) => AdminDomain.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'balanceUsd': 'balance_usd'});

Map<String, dynamic> _$AdminDomainsToJson(AdminDomains instance) =>
    <String, dynamic>{
      'counts': instance.counts.toJson(),
      'balance_usd': instance.balanceUsd,
      'orders': instance.orders.map((e) => e.toJson()).toList(),
      'domains': instance.domains.map((e) => e.toJson()).toList(),
    };
