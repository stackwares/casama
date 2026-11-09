// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CredentialListCWProxy {
  CredentialList items(List<Credential> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CredentialList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CredentialList(...).copyWith(id: 12, name: "My name")
  /// ```
  CredentialList call({List<Credential> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCredentialList.copyWith(...)` or call `instanceOfCredentialList.copyWith.fieldName(value)` for a single field.
class _$CredentialListCWProxyImpl implements _$CredentialListCWProxy {
  const _$CredentialListCWProxyImpl(this._value);

  final CredentialList _value;

  @override
  CredentialList items(List<Credential> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CredentialList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CredentialList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CredentialList call({Object? items = const $CopyWithPlaceholder()}) {
    return CredentialList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Credential>,
    );
  }
}

extension $CredentialListCopyWith on CredentialList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCredentialList.copyWith(...)` or `instanceOfCredentialList.copyWith.fieldName(...)`.
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
