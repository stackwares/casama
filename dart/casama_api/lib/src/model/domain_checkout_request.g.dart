// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_checkout_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainCheckoutRequestCWProxy {
  DomainCheckoutRequest name(String name);

  DomainCheckoutRequest pageId(String? pageId);

  DomainCheckoutRequest acceptTerms(bool acceptTerms);

  DomainCheckoutRequest autoRenew(bool? autoRenew);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainCheckoutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainCheckoutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainCheckoutRequest call({
    String name,
    String? pageId,
    bool acceptTerms,
    bool? autoRenew,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainCheckoutRequest.copyWith(...)` or call `instanceOfDomainCheckoutRequest.copyWith.fieldName(value)` for a single field.
class _$DomainCheckoutRequestCWProxyImpl
    implements _$DomainCheckoutRequestCWProxy {
  const _$DomainCheckoutRequestCWProxyImpl(this._value);

  final DomainCheckoutRequest _value;

  @override
  DomainCheckoutRequest name(String name) => call(name: name);

  @override
  DomainCheckoutRequest pageId(String? pageId) => call(pageId: pageId);

  @override
  DomainCheckoutRequest acceptTerms(bool acceptTerms) =>
      call(acceptTerms: acceptTerms);

  @override
  DomainCheckoutRequest autoRenew(bool? autoRenew) =>
      call(autoRenew: autoRenew);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainCheckoutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainCheckoutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainCheckoutRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? pageId = const $CopyWithPlaceholder(),
    Object? acceptTerms = const $CopyWithPlaceholder(),
    Object? autoRenew = const $CopyWithPlaceholder(),
  }) {
    return DomainCheckoutRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      pageId: pageId == const $CopyWithPlaceholder()
          ? _value.pageId
          // ignore: cast_nullable_to_non_nullable
          : pageId as String?,
      acceptTerms:
          acceptTerms == const $CopyWithPlaceholder() || acceptTerms == null
          ? _value.acceptTerms
          // ignore: cast_nullable_to_non_nullable
          : acceptTerms as bool,
      autoRenew: autoRenew == const $CopyWithPlaceholder()
          ? _value.autoRenew
          // ignore: cast_nullable_to_non_nullable
          : autoRenew as bool?,
    );
  }
}

extension $DomainCheckoutRequestCopyWith on DomainCheckoutRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainCheckoutRequest.copyWith(...)` or `instanceOfDomainCheckoutRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainCheckoutRequestCWProxy get copyWith =>
      _$DomainCheckoutRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainCheckoutRequest _$DomainCheckoutRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DomainCheckoutRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['name', 'accept_terms']);
    final val = DomainCheckoutRequest(
      name: $checkedConvert('name', (v) => v as String),
      pageId: $checkedConvert('page_id', (v) => v as String?),
      acceptTerms: $checkedConvert('accept_terms', (v) => v as bool),
      autoRenew: $checkedConvert('auto_renew', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'pageId': 'page_id',
    'acceptTerms': 'accept_terms',
    'autoRenew': 'auto_renew',
  },
);

Map<String, dynamic> _$DomainCheckoutRequestToJson(
  DomainCheckoutRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'page_id': ?instance.pageId,
  'accept_terms': instance.acceptTerms,
  'auto_renew': ?instance.autoRenew,
};
