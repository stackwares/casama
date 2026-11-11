// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_join_domain_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetJoinDomainRequestCWProxy {
  SetJoinDomainRequest enabled(bool enabled);

  SetJoinDomainRequest domain(String? domain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetJoinDomainRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetJoinDomainRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetJoinDomainRequest call({bool enabled, String? domain});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetJoinDomainRequest.copyWith(...)` or call `instanceOfSetJoinDomainRequest.copyWith.fieldName(value)` for a single field.
class _$SetJoinDomainRequestCWProxyImpl
    implements _$SetJoinDomainRequestCWProxy {
  const _$SetJoinDomainRequestCWProxyImpl(this._value);

  final SetJoinDomainRequest _value;

  @override
  SetJoinDomainRequest enabled(bool enabled) => call(enabled: enabled);

  @override
  SetJoinDomainRequest domain(String? domain) => call(domain: domain);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetJoinDomainRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetJoinDomainRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetJoinDomainRequest call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? domain = const $CopyWithPlaceholder(),
  }) {
    return SetJoinDomainRequest(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      domain: domain == const $CopyWithPlaceholder()
          ? _value.domain
          // ignore: cast_nullable_to_non_nullable
          : domain as String?,
    );
  }
}

extension $SetJoinDomainRequestCopyWith on SetJoinDomainRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetJoinDomainRequest.copyWith(...)` or `instanceOfSetJoinDomainRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetJoinDomainRequestCWProxy get copyWith =>
      _$SetJoinDomainRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetJoinDomainRequest _$SetJoinDomainRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetJoinDomainRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['enabled']);
  final val = SetJoinDomainRequest(
    enabled: $checkedConvert('enabled', (v) => v as bool),
    domain: $checkedConvert('domain', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$SetJoinDomainRequestToJson(
  SetJoinDomainRequest instance,
) => <String, dynamic>{'enabled': instance.enabled, 'domain': ?instance.domain};
