// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_address_check.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteAddressCheckCWProxy {
  SiteAddressCheck label(String label);

  SiteAddressCheck available(bool available);

  SiteAddressCheck reason(String? reason);

  SiteAddressCheck message(String? message);

  SiteAddressCheck url(String? url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteAddressCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteAddressCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  SiteAddressCheck call({
    String label,
    bool available,
    String? reason,
    String? message,
    String? url,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSiteAddressCheck.copyWith(...)` or call `instanceOfSiteAddressCheck.copyWith.fieldName(value)` for a single field.
class _$SiteAddressCheckCWProxyImpl implements _$SiteAddressCheckCWProxy {
  const _$SiteAddressCheckCWProxyImpl(this._value);

  final SiteAddressCheck _value;

  @override
  SiteAddressCheck label(String label) => call(label: label);

  @override
  SiteAddressCheck available(bool available) => call(available: available);

  @override
  SiteAddressCheck reason(String? reason) => call(reason: reason);

  @override
  SiteAddressCheck message(String? message) => call(message: message);

  @override
  SiteAddressCheck url(String? url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteAddressCheck(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteAddressCheck(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SiteAddressCheck call({
    Object? label = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return SiteAddressCheck(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      available: available == const $CopyWithPlaceholder() || available == null
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String?,
      url: url == const $CopyWithPlaceholder()
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String?,
    );
  }
}

extension $SiteAddressCheckCopyWith on SiteAddressCheck {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSiteAddressCheck.copyWith(...)` or `instanceOfSiteAddressCheck.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteAddressCheckCWProxy get copyWith => _$SiteAddressCheckCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteAddressCheck _$SiteAddressCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteAddressCheck', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['label', 'available', 'reason', 'message', 'url'],
      );
      final val = SiteAddressCheck(
        label: $checkedConvert('label', (v) => v as String),
        available: $checkedConvert('available', (v) => v as bool),
        reason: $checkedConvert('reason', (v) => v as String?),
        message: $checkedConvert('message', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SiteAddressCheckToJson(SiteAddressCheck instance) =>
    <String, dynamic>{
      'label': instance.label,
      'available': instance.available,
      'reason': instance.reason,
      'message': instance.message,
      'url': instance.url,
    };
