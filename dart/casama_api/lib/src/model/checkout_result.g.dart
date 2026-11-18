// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckoutResultCWProxy {
  CheckoutResult url(String url);

  CheckoutResult changed(bool? changed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckoutResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckoutResult(...).copyWith(id: 12, name: "My name")
  /// ```
  CheckoutResult call({String url, bool? changed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCheckoutResult.copyWith(...)` or call `instanceOfCheckoutResult.copyWith.fieldName(value)` for a single field.
class _$CheckoutResultCWProxyImpl implements _$CheckoutResultCWProxy {
  const _$CheckoutResultCWProxyImpl(this._value);

  final CheckoutResult _value;

  @override
  CheckoutResult url(String url) => call(url: url);

  @override
  CheckoutResult changed(bool? changed) => call(changed: changed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckoutResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckoutResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CheckoutResult call({
    Object? url = const $CopyWithPlaceholder(),
    Object? changed = const $CopyWithPlaceholder(),
  }) {
    return CheckoutResult(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      changed: changed == const $CopyWithPlaceholder()
          ? _value.changed
          // ignore: cast_nullable_to_non_nullable
          : changed as bool?,
    );
  }
}

extension $CheckoutResultCopyWith on CheckoutResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCheckoutResult.copyWith(...)` or `instanceOfCheckoutResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckoutResultCWProxy get copyWith => _$CheckoutResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutResult _$CheckoutResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CheckoutResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url']);
      final val = CheckoutResult(
        url: $checkedConvert('url', (v) => v as String),
        changed: $checkedConvert('changed', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$CheckoutResultToJson(CheckoutResult instance) =>
    <String, dynamic>{'url': instance.url, 'changed': ?instance.changed};
