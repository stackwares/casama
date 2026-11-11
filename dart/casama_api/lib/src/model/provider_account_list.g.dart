// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_account_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderAccountListCWProxy {
  ProviderAccountList items(List<ProviderAccount> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderAccountList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderAccountList(...).copyWith(id: 12, name: "My name")
  /// ```
  ProviderAccountList call({List<ProviderAccount> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProviderAccountList.copyWith(...)` or call `instanceOfProviderAccountList.copyWith.fieldName(value)` for a single field.
class _$ProviderAccountListCWProxyImpl implements _$ProviderAccountListCWProxy {
  const _$ProviderAccountListCWProxyImpl(this._value);

  final ProviderAccountList _value;

  @override
  ProviderAccountList items(List<ProviderAccount> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProviderAccountList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProviderAccountList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProviderAccountList call({Object? items = const $CopyWithPlaceholder()}) {
    return ProviderAccountList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ProviderAccount>,
    );
  }
}

extension $ProviderAccountListCopyWith on ProviderAccountList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProviderAccountList.copyWith(...)` or `instanceOfProviderAccountList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderAccountListCWProxy get copyWith =>
      _$ProviderAccountListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderAccountList _$ProviderAccountListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProviderAccountList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ProviderAccountList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ProviderAccount.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProviderAccountListToJson(
  ProviderAccountList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
