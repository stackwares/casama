// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_price_tables_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SavePriceTablesRequestCWProxy {
  SavePriceTablesRequest costTables(Map<String, Object?>? costTables);

  SavePriceTablesRequest domainTlds(List<String>? domainTlds);

  SavePriceTablesRequest domainCapFirstMonth(int? domainCapFirstMonth);

  SavePriceTablesRequest domainCapPerMonth(int? domainCapPerMonth);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavePriceTablesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavePriceTablesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SavePriceTablesRequest call({
    Map<String, Object?>? costTables,
    List<String>? domainTlds,
    int? domainCapFirstMonth,
    int? domainCapPerMonth,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSavePriceTablesRequest.copyWith(...)` or call `instanceOfSavePriceTablesRequest.copyWith.fieldName(value)` for a single field.
class _$SavePriceTablesRequestCWProxyImpl
    implements _$SavePriceTablesRequestCWProxy {
  const _$SavePriceTablesRequestCWProxyImpl(this._value);

  final SavePriceTablesRequest _value;

  @override
  SavePriceTablesRequest costTables(Map<String, Object?>? costTables) =>
      call(costTables: costTables);

  @override
  SavePriceTablesRequest domainTlds(List<String>? domainTlds) =>
      call(domainTlds: domainTlds);

  @override
  SavePriceTablesRequest domainCapFirstMonth(int? domainCapFirstMonth) =>
      call(domainCapFirstMonth: domainCapFirstMonth);

  @override
  SavePriceTablesRequest domainCapPerMonth(int? domainCapPerMonth) =>
      call(domainCapPerMonth: domainCapPerMonth);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavePriceTablesRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavePriceTablesRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SavePriceTablesRequest call({
    Object? costTables = const $CopyWithPlaceholder(),
    Object? domainTlds = const $CopyWithPlaceholder(),
    Object? domainCapFirstMonth = const $CopyWithPlaceholder(),
    Object? domainCapPerMonth = const $CopyWithPlaceholder(),
  }) {
    return SavePriceTablesRequest(
      costTables: costTables == const $CopyWithPlaceholder()
          ? _value.costTables
          // ignore: cast_nullable_to_non_nullable
          : costTables as Map<String, Object?>?,
      domainTlds: domainTlds == const $CopyWithPlaceholder()
          ? _value.domainTlds
          // ignore: cast_nullable_to_non_nullable
          : domainTlds as List<String>?,
      domainCapFirstMonth: domainCapFirstMonth == const $CopyWithPlaceholder()
          ? _value.domainCapFirstMonth
          // ignore: cast_nullable_to_non_nullable
          : domainCapFirstMonth as int?,
      domainCapPerMonth: domainCapPerMonth == const $CopyWithPlaceholder()
          ? _value.domainCapPerMonth
          // ignore: cast_nullable_to_non_nullable
          : domainCapPerMonth as int?,
    );
  }
}

extension $SavePriceTablesRequestCopyWith on SavePriceTablesRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSavePriceTablesRequest.copyWith(...)` or `instanceOfSavePriceTablesRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SavePriceTablesRequestCWProxy get copyWith =>
      _$SavePriceTablesRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavePriceTablesRequest _$SavePriceTablesRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SavePriceTablesRequest',
  json,
  ($checkedConvert) {
    final val = SavePriceTablesRequest(
      costTables: $checkedConvert(
        'cost_tables',
        (v) => v as Map<String, dynamic>?,
      ),
      domainTlds: $checkedConvert(
        'domain_tlds',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      domainCapFirstMonth: $checkedConvert(
        'domain_cap_first_month',
        (v) => (v as num?)?.toInt(),
      ),
      domainCapPerMonth: $checkedConvert(
        'domain_cap_per_month',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'costTables': 'cost_tables',
    'domainTlds': 'domain_tlds',
    'domainCapFirstMonth': 'domain_cap_first_month',
    'domainCapPerMonth': 'domain_cap_per_month',
  },
);

Map<String, dynamic> _$SavePriceTablesRequestToJson(
  SavePriceTablesRequest instance,
) => <String, dynamic>{
  'cost_tables': ?instance.costTables,
  'domain_tlds': ?instance.domainTlds,
  'domain_cap_first_month': ?instance.domainCapFirstMonth,
  'domain_cap_per_month': ?instance.domainCapPerMonth,
};
