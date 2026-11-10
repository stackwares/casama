// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_manager_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PasswordManagerListCWProxy {
  PasswordManagerList items(List<PasswordManager> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManagerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManagerList(...).copyWith(id: 12, name: "My name")
  /// ```
  PasswordManagerList call({List<PasswordManager> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPasswordManagerList.copyWith(...)` or call `instanceOfPasswordManagerList.copyWith.fieldName(value)` for a single field.
class _$PasswordManagerListCWProxyImpl implements _$PasswordManagerListCWProxy {
  const _$PasswordManagerListCWProxyImpl(this._value);

  final PasswordManagerList _value;

  @override
  PasswordManagerList items(List<PasswordManager> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PasswordManagerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PasswordManagerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PasswordManagerList call({Object? items = const $CopyWithPlaceholder()}) {
    return PasswordManagerList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PasswordManager>,
    );
  }
}

extension $PasswordManagerListCopyWith on PasswordManagerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPasswordManagerList.copyWith(...)` or `instanceOfPasswordManagerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PasswordManagerListCWProxy get copyWith =>
      _$PasswordManagerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasswordManagerList _$PasswordManagerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PasswordManagerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PasswordManagerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PasswordManager.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PasswordManagerListToJson(
  PasswordManagerList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
