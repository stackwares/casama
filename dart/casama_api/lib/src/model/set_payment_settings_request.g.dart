// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_payment_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetPaymentSettingsRequestCWProxy {
  SetPaymentSettingsRequest secretKey(String secretKey);

  SetPaymentSettingsRequest webhookSecret(String webhookSecret);

  SetPaymentSettingsRequest cardholder(
    SetPaymentSettingsRequestCardholder cardholder,
  );

  SetPaymentSettingsRequest monthlyCapUsd(num? monthlyCapUsd);

  SetPaymentSettingsRequest botMonthlyCapUsd(num? botMonthlyCapUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetPaymentSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetPaymentSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetPaymentSettingsRequest call({
    String secretKey,
    String webhookSecret,
    SetPaymentSettingsRequestCardholder cardholder,
    num? monthlyCapUsd,
    num? botMonthlyCapUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetPaymentSettingsRequest.copyWith(...)` or call `instanceOfSetPaymentSettingsRequest.copyWith.fieldName(value)` for a single field.
class _$SetPaymentSettingsRequestCWProxyImpl
    implements _$SetPaymentSettingsRequestCWProxy {
  const _$SetPaymentSettingsRequestCWProxyImpl(this._value);

  final SetPaymentSettingsRequest _value;

  @override
  SetPaymentSettingsRequest secretKey(String secretKey) =>
      call(secretKey: secretKey);

  @override
  SetPaymentSettingsRequest webhookSecret(String webhookSecret) =>
      call(webhookSecret: webhookSecret);

  @override
  SetPaymentSettingsRequest cardholder(
    SetPaymentSettingsRequestCardholder cardholder,
  ) => call(cardholder: cardholder);

  @override
  SetPaymentSettingsRequest monthlyCapUsd(num? monthlyCapUsd) =>
      call(monthlyCapUsd: monthlyCapUsd);

  @override
  SetPaymentSettingsRequest botMonthlyCapUsd(num? botMonthlyCapUsd) =>
      call(botMonthlyCapUsd: botMonthlyCapUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetPaymentSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetPaymentSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetPaymentSettingsRequest call({
    Object? secretKey = const $CopyWithPlaceholder(),
    Object? webhookSecret = const $CopyWithPlaceholder(),
    Object? cardholder = const $CopyWithPlaceholder(),
    Object? monthlyCapUsd = const $CopyWithPlaceholder(),
    Object? botMonthlyCapUsd = const $CopyWithPlaceholder(),
  }) {
    return SetPaymentSettingsRequest(
      secretKey: secretKey == const $CopyWithPlaceholder() || secretKey == null
          ? _value.secretKey
          // ignore: cast_nullable_to_non_nullable
          : secretKey as String,
      webhookSecret:
          webhookSecret == const $CopyWithPlaceholder() || webhookSecret == null
          ? _value.webhookSecret
          // ignore: cast_nullable_to_non_nullable
          : webhookSecret as String,
      cardholder:
          cardholder == const $CopyWithPlaceholder() || cardholder == null
          ? _value.cardholder
          // ignore: cast_nullable_to_non_nullable
          : cardholder as SetPaymentSettingsRequestCardholder,
      monthlyCapUsd: monthlyCapUsd == const $CopyWithPlaceholder()
          ? _value.monthlyCapUsd
          // ignore: cast_nullable_to_non_nullable
          : monthlyCapUsd as num?,
      botMonthlyCapUsd: botMonthlyCapUsd == const $CopyWithPlaceholder()
          ? _value.botMonthlyCapUsd
          // ignore: cast_nullable_to_non_nullable
          : botMonthlyCapUsd as num?,
    );
  }
}

extension $SetPaymentSettingsRequestCopyWith on SetPaymentSettingsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetPaymentSettingsRequest.copyWith(...)` or `instanceOfSetPaymentSettingsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetPaymentSettingsRequestCWProxy get copyWith =>
      _$SetPaymentSettingsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetPaymentSettingsRequest _$SetPaymentSettingsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SetPaymentSettingsRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['secret_key', 'webhook_secret', 'cardholder'],
    );
    final val = SetPaymentSettingsRequest(
      secretKey: $checkedConvert('secret_key', (v) => v as String),
      webhookSecret: $checkedConvert('webhook_secret', (v) => v as String),
      cardholder: $checkedConvert(
        'cardholder',
        (v) => SetPaymentSettingsRequestCardholder.fromJson(
          v as Map<String, dynamic>,
        ),
      ),
      monthlyCapUsd: $checkedConvert('monthly_cap_usd', (v) => v as num?),
      botMonthlyCapUsd: $checkedConvert(
        'bot_monthly_cap_usd',
        (v) => v as num?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'secretKey': 'secret_key',
    'webhookSecret': 'webhook_secret',
    'monthlyCapUsd': 'monthly_cap_usd',
    'botMonthlyCapUsd': 'bot_monthly_cap_usd',
  },
);

Map<String, dynamic> _$SetPaymentSettingsRequestToJson(
  SetPaymentSettingsRequest instance,
) => <String, dynamic>{
  'secret_key': instance.secretKey,
  'webhook_secret': instance.webhookSecret,
  'cardholder': instance.cardholder.toJson(),
  'monthly_cap_usd': ?instance.monthlyCapUsd,
  'bot_monthly_cap_usd': ?instance.botMonthlyCapUsd,
};
