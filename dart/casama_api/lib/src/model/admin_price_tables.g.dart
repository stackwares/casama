// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_price_tables.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPriceTablesCWProxy {
  AdminPriceTables costTables(Map<String, Object?> costTables);

  AdminPriceTables builtIn(Map<String, Object?> builtIn);

  AdminPriceTables domainTlds(List<String> domainTlds);

  AdminPriceTables domainTldsSaved(bool domainTldsSaved);

  AdminPriceTables domainCapFirstMonth(int domainCapFirstMonth);

  AdminPriceTables domainCapPerMonth(int domainCapPerMonth);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPriceTables(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPriceTables(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPriceTables call({
    Map<String, Object?> costTables,
    Map<String, Object?> builtIn,
    List<String> domainTlds,
    bool domainTldsSaved,
    int domainCapFirstMonth,
    int domainCapPerMonth,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPriceTables.copyWith(...)` or call `instanceOfAdminPriceTables.copyWith.fieldName(value)` for a single field.
class _$AdminPriceTablesCWProxyImpl implements _$AdminPriceTablesCWProxy {
  const _$AdminPriceTablesCWProxyImpl(this._value);

  final AdminPriceTables _value;

  @override
  AdminPriceTables costTables(Map<String, Object?> costTables) =>
      call(costTables: costTables);

  @override
  AdminPriceTables builtIn(Map<String, Object?> builtIn) =>
      call(builtIn: builtIn);

  @override
  AdminPriceTables domainTlds(List<String> domainTlds) =>
      call(domainTlds: domainTlds);

  @override
  AdminPriceTables domainTldsSaved(bool domainTldsSaved) =>
      call(domainTldsSaved: domainTldsSaved);

  @override
  AdminPriceTables domainCapFirstMonth(int domainCapFirstMonth) =>
      call(domainCapFirstMonth: domainCapFirstMonth);

  @override
  AdminPriceTables domainCapPerMonth(int domainCapPerMonth) =>
      call(domainCapPerMonth: domainCapPerMonth);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPriceTables(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPriceTables(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPriceTables call({
    Object? costTables = const $CopyWithPlaceholder(),
    Object? builtIn = const $CopyWithPlaceholder(),
    Object? domainTlds = const $CopyWithPlaceholder(),
    Object? domainTldsSaved = const $CopyWithPlaceholder(),
    Object? domainCapFirstMonth = const $CopyWithPlaceholder(),
    Object? domainCapPerMonth = const $CopyWithPlaceholder(),
  }) {
    return AdminPriceTables(
      costTables:
          costTables == const $CopyWithPlaceholder() || costTables == null
          ? _value.costTables
          // ignore: cast_nullable_to_non_nullable
          : costTables as Map<String, Object?>,
      builtIn: builtIn == const $CopyWithPlaceholder() || builtIn == null
          ? _value.builtIn
          // ignore: cast_nullable_to_non_nullable
          : builtIn as Map<String, Object?>,
      domainTlds:
          domainTlds == const $CopyWithPlaceholder() || domainTlds == null
          ? _value.domainTlds
          // ignore: cast_nullable_to_non_nullable
          : domainTlds as List<String>,
      domainTldsSaved:
          domainTldsSaved == const $CopyWithPlaceholder() ||
              domainTldsSaved == null
          ? _value.domainTldsSaved
          // ignore: cast_nullable_to_non_nullable
          : domainTldsSaved as bool,
      domainCapFirstMonth:
          domainCapFirstMonth == const $CopyWithPlaceholder() ||
              domainCapFirstMonth == null
          ? _value.domainCapFirstMonth
          // ignore: cast_nullable_to_non_nullable
          : domainCapFirstMonth as int,
      domainCapPerMonth:
          domainCapPerMonth == const $CopyWithPlaceholder() ||
              domainCapPerMonth == null
          ? _value.domainCapPerMonth
          // ignore: cast_nullable_to_non_nullable
          : domainCapPerMonth as int,
    );
  }
}

extension $AdminPriceTablesCopyWith on AdminPriceTables {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPriceTables.copyWith(...)` or `instanceOfAdminPriceTables.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPriceTablesCWProxy get copyWith => _$AdminPriceTablesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPriceTables _$AdminPriceTablesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminPriceTables',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'cost_tables',
        'built_in',
        'domain_tlds',
        'domain_tlds_saved',
        'domain_cap_first_month',
        'domain_cap_per_month',
      ],
    );
    final val = AdminPriceTables(
      costTables: $checkedConvert(
        'cost_tables',
        (v) => v as Map<String, dynamic>,
      ),
      builtIn: $checkedConvert('built_in', (v) => v as Map<String, dynamic>),
      domainTlds: $checkedConvert(
        'domain_tlds',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      domainTldsSaved: $checkedConvert('domain_tlds_saved', (v) => v as bool),
      domainCapFirstMonth: $checkedConvert(
        'domain_cap_first_month',
        (v) => (v as num).toInt(),
      ),
      domainCapPerMonth: $checkedConvert(
        'domain_cap_per_month',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'costTables': 'cost_tables',
    'builtIn': 'built_in',
    'domainTlds': 'domain_tlds',
    'domainTldsSaved': 'domain_tlds_saved',
    'domainCapFirstMonth': 'domain_cap_first_month',
    'domainCapPerMonth': 'domain_cap_per_month',
  },
);

Map<String, dynamic> _$AdminPriceTablesToJson(AdminPriceTables instance) =>
    <String, dynamic>{
      'cost_tables': instance.costTables,
      'built_in': instance.builtIn,
      'domain_tlds': instance.domainTlds,
      'domain_tlds_saved': instance.domainTldsSaved,
      'domain_cap_first_month': instance.domainCapFirstMonth,
      'domain_cap_per_month': instance.domainCapPerMonth,
    };
