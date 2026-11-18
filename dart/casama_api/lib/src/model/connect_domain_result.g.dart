// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_domain_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectDomainResultCWProxy {
  ConnectDomainResult domain(Domain? domain);

  ConnectDomainResult claim(ConnectDomainResultClaim? claim);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectDomainResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectDomainResult(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectDomainResult call({Domain? domain, ConnectDomainResultClaim? claim});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectDomainResult.copyWith(...)` or call `instanceOfConnectDomainResult.copyWith.fieldName(value)` for a single field.
class _$ConnectDomainResultCWProxyImpl implements _$ConnectDomainResultCWProxy {
  const _$ConnectDomainResultCWProxyImpl(this._value);

  final ConnectDomainResult _value;

  @override
  ConnectDomainResult domain(Domain? domain) => call(domain: domain);

  @override
  ConnectDomainResult claim(ConnectDomainResultClaim? claim) =>
      call(claim: claim);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectDomainResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectDomainResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectDomainResult call({
    Object? domain = const $CopyWithPlaceholder(),
    Object? claim = const $CopyWithPlaceholder(),
  }) {
    return ConnectDomainResult(
      domain: domain == const $CopyWithPlaceholder()
          ? _value.domain
          // ignore: cast_nullable_to_non_nullable
          : domain as Domain?,
      claim: claim == const $CopyWithPlaceholder()
          ? _value.claim
          // ignore: cast_nullable_to_non_nullable
          : claim as ConnectDomainResultClaim?,
    );
  }
}

extension $ConnectDomainResultCopyWith on ConnectDomainResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectDomainResult.copyWith(...)` or `instanceOfConnectDomainResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectDomainResultCWProxy get copyWith =>
      _$ConnectDomainResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectDomainResult _$ConnectDomainResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ConnectDomainResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['domain', 'claim']);
      final val = ConnectDomainResult(
        domain: $checkedConvert(
          'domain',
          (v) => v == null ? null : Domain.fromJson(v as Map<String, dynamic>),
        ),
        claim: $checkedConvert(
          'claim',
          (v) => v == null
              ? null
              : ConnectDomainResultClaim.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ConnectDomainResultToJson(
  ConnectDomainResult instance,
) => <String, dynamic>{
  'domain': instance.domain?.toJson(),
  'claim': instance.claim?.toJson(),
};
