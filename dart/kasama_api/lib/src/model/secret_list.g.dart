// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretListCWProxy {
  SecretList items(List<Secret> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SecretList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SecretList(...).copyWith(id: 12, name: "My name")
  /// ````
  SecretList call({List<Secret> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSecretList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSecretList.copyWith.fieldName(...)`
class _$SecretListCWProxyImpl implements _$SecretListCWProxy {
  const _$SecretListCWProxyImpl(this._value);

  final SecretList _value;

  @override
  SecretList items(List<Secret> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SecretList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SecretList(...).copyWith(id: 12, name: "My name")
  /// ````
  SecretList call({Object? items = const $CopyWithPlaceholder()}) {
    return SecretList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Secret>,
    );
  }
}

extension $SecretListCopyWith on SecretList {
  /// Returns a callable class that can be used as follows: `instanceOfSecretList.copyWith(...)` or like so:`instanceOfSecretList.copyWith.fieldName(...)`.
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
