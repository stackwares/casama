// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentSettingsCWProxy {
  PaymentSettings connected(bool connected);

  PaymentSettings provider(PaymentSettingsProviderEnum? provider);

  PaymentSettings monthlyCapUsd(num monthlyCapUsd);

  PaymentSettings botMonthlyCapUsd(num botMonthlyCapUsd);

  PaymentSettings spentThisMonthUsd(num spentThisMonthUsd);

  PaymentSettings webhookUrl(String? webhookUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentSettings call({
    bool connected,
    PaymentSettingsProviderEnum? provider,
    num monthlyCapUsd,
    num botMonthlyCapUsd,
    num spentThisMonthUsd,
    String? webhookUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentSettings.copyWith(...)` or call `instanceOfPaymentSettings.copyWith.fieldName(value)` for a single field.
class _$PaymentSettingsCWProxyImpl implements _$PaymentSettingsCWProxy {
  const _$PaymentSettingsCWProxyImpl(this._value);

  final PaymentSettings _value;

  @override
  PaymentSettings connected(bool connected) => call(connected: connected);

  @override
  PaymentSettings provider(PaymentSettingsProviderEnum? provider) =>
      call(provider: provider);

  @override
  PaymentSettings monthlyCapUsd(num monthlyCapUsd) =>
      call(monthlyCapUsd: monthlyCapUsd);

  @override
  PaymentSettings botMonthlyCapUsd(num botMonthlyCapUsd) =>
      call(botMonthlyCapUsd: botMonthlyCapUsd);

  @override
  PaymentSettings spentThisMonthUsd(num spentThisMonthUsd) =>
      call(spentThisMonthUsd: spentThisMonthUsd);

  @override
  PaymentSettings webhookUrl(String? webhookUrl) =>
      call(webhookUrl: webhookUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentSettings call({
    Object? connected = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? monthlyCapUsd = const $CopyWithPlaceholder(),
    Object? botMonthlyCapUsd = const $CopyWithPlaceholder(),
    Object? spentThisMonthUsd = const $CopyWithPlaceholder(),
    Object? webhookUrl = const $CopyWithPlaceholder(),
  }) {
    return PaymentSettings(
      connected: connected == const $CopyWithPlaceholder() || connected == null
          ? _value.connected
          // ignore: cast_nullable_to_non_nullable
          : connected as bool,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as PaymentSettingsProviderEnum?,
      monthlyCapUsd:
          monthlyCapUsd == const $CopyWithPlaceholder() || monthlyCapUsd == null
          ? _value.monthlyCapUsd
          // ignore: cast_nullable_to_non_nullable
          : monthlyCapUsd as num,
      botMonthlyCapUsd:
          botMonthlyCapUsd == const $CopyWithPlaceholder() ||
              botMonthlyCapUsd == null
          ? _value.botMonthlyCapUsd
          // ignore: cast_nullable_to_non_nullable
          : botMonthlyCapUsd as num,
      spentThisMonthUsd:
          spentThisMonthUsd == const $CopyWithPlaceholder() ||
              spentThisMonthUsd == null
          ? _value.spentThisMonthUsd
          // ignore: cast_nullable_to_non_nullable
          : spentThisMonthUsd as num,
      webhookUrl: webhookUrl == const $CopyWithPlaceholder()
          ? _value.webhookUrl
          // ignore: cast_nullable_to_non_nullable
          : webhookUrl as String?,
    );
  }
}

extension $PaymentSettingsCopyWith on PaymentSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentSettings.copyWith(...)` or `instanceOfPaymentSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentSettingsCWProxy get copyWith => _$PaymentSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentSettings _$PaymentSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PaymentSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'connected',
            'provider',
            'monthly_cap_usd',
            'bot_monthly_cap_usd',
            'spent_this_month_usd',
            'webhook_url',
          ],
        );
        final val = PaymentSettings(
          connected: $checkedConvert('connected', (v) => v as bool),
          provider: $checkedConvert(
            'provider',
            (v) => $enumDecodeNullable(_$PaymentSettingsProviderEnumEnumMap, v),
          ),
          monthlyCapUsd: $checkedConvert('monthly_cap_usd', (v) => v as num),
          botMonthlyCapUsd: $checkedConvert(
            'bot_monthly_cap_usd',
            (v) => v as num,
          ),
          spentThisMonthUsd: $checkedConvert(
            'spent_this_month_usd',
            (v) => v as num,
          ),
          webhookUrl: $checkedConvert('webhook_url', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'monthlyCapUsd': 'monthly_cap_usd',
        'botMonthlyCapUsd': 'bot_monthly_cap_usd',
        'spentThisMonthUsd': 'spent_this_month_usd',
        'webhookUrl': 'webhook_url',
      },
    );

Map<String, dynamic> _$PaymentSettingsToJson(PaymentSettings instance) =>
    <String, dynamic>{
      'connected': instance.connected,
      'provider': _$PaymentSettingsProviderEnumEnumMap[instance.provider],
      'monthly_cap_usd': instance.monthlyCapUsd,
      'bot_monthly_cap_usd': instance.botMonthlyCapUsd,
      'spent_this_month_usd': instance.spentThisMonthUsd,
      'webhook_url': instance.webhookUrl,
    };

const _$PaymentSettingsProviderEnumEnumMap = {
  PaymentSettingsProviderEnum.stripe: 'stripe',
};
