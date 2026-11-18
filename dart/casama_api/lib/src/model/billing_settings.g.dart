// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingSettingsCWProxy {
  BillingSettings markup(num markup);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingSettings call({num markup});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingSettings.copyWith(...)` or call `instanceOfBillingSettings.copyWith.fieldName(value)` for a single field.
class _$BillingSettingsCWProxyImpl implements _$BillingSettingsCWProxy {
  const _$BillingSettingsCWProxyImpl(this._value);

  final BillingSettings _value;

  @override
  BillingSettings markup(num markup) => call(markup: markup);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingSettings call({Object? markup = const $CopyWithPlaceholder()}) {
    return BillingSettings(
      markup: markup == const $CopyWithPlaceholder() || markup == null
          ? _value.markup
          // ignore: cast_nullable_to_non_nullable
          : markup as num,
    );
  }
}

extension $BillingSettingsCopyWith on BillingSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingSettings.copyWith(...)` or `instanceOfBillingSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingSettingsCWProxy get copyWith => _$BillingSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingSettings _$BillingSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BillingSettings', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['markup']);
      final val = BillingSettings(
        markup: $checkedConvert('markup', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$BillingSettingsToJson(BillingSettings instance) =>
    <String, dynamic>{'markup': instance.markup};
