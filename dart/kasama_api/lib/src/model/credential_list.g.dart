// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CredentialListCWProxy {
  CredentialList items(List<Credential> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CredentialList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CredentialList(...).copyWith(id: 12, name: "My name")
  /// ````
  CredentialList call({List<Credential> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCredentialList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCredentialList.copyWith.fieldName(...)`
class _$CredentialListCWProxyImpl implements _$CredentialListCWProxy {
  const _$CredentialListCWProxyImpl(this._value);

  final CredentialList _value;

  @override
  CredentialList items(List<Credential> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CredentialList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CredentialList(...).copyWith(id: 12, name: "My name")
  /// ````
  CredentialList call({Object? items = const $CopyWithPlaceholder()}) {
    return CredentialList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Credential>,
    );
  }
}

extension $CredentialListCopyWith on CredentialList {
  /// Returns a callable class that can be used as follows: `instanceOfCredentialList.copyWith(...)` or like so:`instanceOfCredentialList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CredentialListCWProxy get copyWith => _$CredentialListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialList _$CredentialListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CredentialList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = CredentialList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Credential.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CredentialListToJson(CredentialList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
