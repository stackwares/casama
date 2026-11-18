// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretListCWProxy {
  SecretList items(List<Secret> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretList(...).copyWith(id: 12, name: "My name")
  /// ```
  SecretList call({List<Secret> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecretList.copyWith(...)` or call `instanceOfSecretList.copyWith.fieldName(value)` for a single field.
class _$SecretListCWProxyImpl implements _$SecretListCWProxy {
  const _$SecretListCWProxyImpl(this._value);

  final SecretList _value;

  @override
  SecretList items(List<Secret> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SecretList call({Object? items = const $CopyWithPlaceholder()}) {
    return SecretList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Secret>,
    );
  }
}

extension $SecretListCopyWith on SecretList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecretList.copyWith(...)` or `instanceOfSecretList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretListCWProxy get copyWith => _$SecretListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretList _$SecretListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SecretList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SecretList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Secret.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SecretListToJson(SecretList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
