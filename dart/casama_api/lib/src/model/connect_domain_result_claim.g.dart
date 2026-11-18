// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_domain_result_claim.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectDomainResultClaimCWProxy {
  ConnectDomainResultClaim type(String type);

  ConnectDomainResultClaim name(String name);

  ConnectDomainResultClaim value(String value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectDomainResultClaim(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectDomainResultClaim(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectDomainResultClaim call({String type, String name, String value});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectDomainResultClaim.copyWith(...)` or call `instanceOfConnectDomainResultClaim.copyWith.fieldName(value)` for a single field.
class _$ConnectDomainResultClaimCWProxyImpl
    implements _$ConnectDomainResultClaimCWProxy {
  const _$ConnectDomainResultClaimCWProxyImpl(this._value);

  final ConnectDomainResultClaim _value;

  @override
  ConnectDomainResultClaim type(String type) => call(type: type);

  @override
  ConnectDomainResultClaim name(String name) => call(name: name);

  @override
  ConnectDomainResultClaim value(String value) => call(value: value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectDomainResultClaim(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectDomainResultClaim(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectDomainResultClaim call({
    Object? type = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return ConnectDomainResultClaim(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $ConnectDomainResultClaimCopyWith on ConnectDomainResultClaim {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectDomainResultClaim.copyWith(...)` or `instanceOfConnectDomainResultClaim.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectDomainResultClaimCWProxy get copyWith =>
      _$ConnectDomainResultClaimCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectDomainResultClaim _$ConnectDomainResultClaimFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConnectDomainResultClaim', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['type', 'name', 'value']);
  final val = ConnectDomainResultClaim(
    type: $checkedConvert('type', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    value: $checkedConvert('value', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ConnectDomainResultClaimToJson(
  ConnectDomainResultClaim instance,
) => <String, dynamic>{
  'type': instance.type,
  'name': instance.name,
  'value': instance.value,
};
