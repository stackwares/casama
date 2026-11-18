// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_manager_vault.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasswordManagerVaultCWProxy {
  PasswordManagerVault id(String id);

  PasswordManagerVault name(String name);

  PasswordManagerVault allowed(bool allowed);

  PasswordManagerVault logins(int? logins);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManagerVault(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManagerVault(...).copyWith(id: 12, name: "My name")
  /// ```
  PasswordManagerVault call({
    String id,
    String name,
    bool allowed,
    int? logins,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPasswordManagerVault.copyWith(...)` or call `instanceOfPasswordManagerVault.copyWith.fieldName(value)` for a single field.
class _$PasswordManagerVaultCWProxyImpl
    implements _$PasswordManagerVaultCWProxy {
  const _$PasswordManagerVaultCWProxyImpl(this._value);

  final PasswordManagerVault _value;

  @override
  PasswordManagerVault id(String id) => call(id: id);

  @override
  PasswordManagerVault name(String name) => call(name: name);

  @override
  PasswordManagerVault allowed(bool allowed) => call(allowed: allowed);

  @override
  PasswordManagerVault logins(int? logins) => call(logins: logins);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManagerVault(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManagerVault(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PasswordManagerVault call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? allowed = const $CopyWithPlaceholder(),
    Object? logins = const $CopyWithPlaceholder(),
  }) {
    return PasswordManagerVault(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      allowed: allowed == const $CopyWithPlaceholder() || allowed == null
          ? _value.allowed
          // ignore: cast_nullable_to_non_nullable
          : allowed as bool,
      logins: logins == const $CopyWithPlaceholder()
          ? _value.logins
          // ignore: cast_nullable_to_non_nullable
          : logins as int?,
    );
  }
}

extension $PasswordManagerVaultCopyWith on PasswordManagerVault {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPasswordManagerVault.copyWith(...)` or `instanceOfPasswordManagerVault.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasswordManagerVaultCWProxy get copyWith =>
      _$PasswordManagerVaultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordManagerVault _$PasswordManagerVaultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PasswordManagerVault', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'name', 'allowed', 'logins']);
  final val = PasswordManagerVault(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    allowed: $checkedConvert('allowed', (v) => v as bool),
    logins: $checkedConvert('logins', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$PasswordManagerVaultToJson(
  PasswordManagerVault instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'allowed': instance.allowed,
  'logins': instance.logins,
};
