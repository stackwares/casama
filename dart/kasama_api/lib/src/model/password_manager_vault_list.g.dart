// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_manager_vault_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasswordManagerVaultListCWProxy {
  PasswordManagerVaultList items(List<PasswordManagerVault> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManagerVaultList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManagerVaultList(...).copyWith(id: 12, name: "My name")
  /// ```
  PasswordManagerVaultList call({List<PasswordManagerVault> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPasswordManagerVaultList.copyWith(...)` or call `instanceOfPasswordManagerVaultList.copyWith.fieldName(value)` for a single field.
class _$PasswordManagerVaultListCWProxyImpl
    implements _$PasswordManagerVaultListCWProxy {
  const _$PasswordManagerVaultListCWProxyImpl(this._value);

  final PasswordManagerVaultList _value;

  @override
  PasswordManagerVaultList items(List<PasswordManagerVault> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManagerVaultList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManagerVaultList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PasswordManagerVaultList call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return PasswordManagerVaultList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PasswordManagerVault>,
    );
  }
}

extension $PasswordManagerVaultListCopyWith on PasswordManagerVaultList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPasswordManagerVaultList.copyWith(...)` or `instanceOfPasswordManagerVaultList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasswordManagerVaultListCWProxy get copyWith =>
      _$PasswordManagerVaultListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordManagerVaultList _$PasswordManagerVaultListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PasswordManagerVaultList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = PasswordManagerVaultList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => PasswordManagerVault.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PasswordManagerVaultListToJson(
  PasswordManagerVaultList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
