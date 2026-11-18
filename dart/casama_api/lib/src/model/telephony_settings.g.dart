// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telephony_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TelephonySettingsCWProxy {
  TelephonySettings connected(bool connected);

  TelephonySettings accountSid(String? accountSid);

  TelephonySettings fromNumber(String? fromNumber);

  TelephonySettings allowPersonalNumbers(bool allowPersonalNumbers);

  TelephonySettings dailyCap(int dailyCap);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TelephonySettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TelephonySettings(...).copyWith(id: 12, name: "My name")
  /// ```
  TelephonySettings call({
    bool connected,
    String? accountSid,
    String? fromNumber,
    bool allowPersonalNumbers,
    int dailyCap,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTelephonySettings.copyWith(...)` or call `instanceOfTelephonySettings.copyWith.fieldName(value)` for a single field.
class _$TelephonySettingsCWProxyImpl implements _$TelephonySettingsCWProxy {
  const _$TelephonySettingsCWProxyImpl(this._value);

  final TelephonySettings _value;

  @override
  TelephonySettings connected(bool connected) => call(connected: connected);

  @override
  TelephonySettings accountSid(String? accountSid) =>
      call(accountSid: accountSid);

  @override
  TelephonySettings fromNumber(String? fromNumber) =>
      call(fromNumber: fromNumber);

  @override
  TelephonySettings allowPersonalNumbers(bool allowPersonalNumbers) =>
      call(allowPersonalNumbers: allowPersonalNumbers);

  @override
  TelephonySettings dailyCap(int dailyCap) => call(dailyCap: dailyCap);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TelephonySettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TelephonySettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TelephonySettings call({
    Object? connected = const $CopyWithPlaceholder(),
    Object? accountSid = const $CopyWithPlaceholder(),
    Object? fromNumber = const $CopyWithPlaceholder(),
    Object? allowPersonalNumbers = const $CopyWithPlaceholder(),
    Object? dailyCap = const $CopyWithPlaceholder(),
  }) {
    return TelephonySettings(
      connected: connected == const $CopyWithPlaceholder() || connected == null
          ? _value.connected
          // ignore: cast_nullable_to_non_nullable
          : connected as bool,
      accountSid: accountSid == const $CopyWithPlaceholder()
          ? _value.accountSid
          // ignore: cast_nullable_to_non_nullable
          : accountSid as String?,
      fromNumber: fromNumber == const $CopyWithPlaceholder()
          ? _value.fromNumber
          // ignore: cast_nullable_to_non_nullable
          : fromNumber as String?,
      allowPersonalNumbers:
          allowPersonalNumbers == const $CopyWithPlaceholder() ||
              allowPersonalNumbers == null
          ? _value.allowPersonalNumbers
          // ignore: cast_nullable_to_non_nullable
          : allowPersonalNumbers as bool,
      dailyCap: dailyCap == const $CopyWithPlaceholder() || dailyCap == null
          ? _value.dailyCap
          // ignore: cast_nullable_to_non_nullable
          : dailyCap as int,
    );
  }
}

extension $TelephonySettingsCopyWith on TelephonySettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTelephonySettings.copyWith(...)` or `instanceOfTelephonySettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TelephonySettingsCWProxy get copyWith =>
      _$TelephonySettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TelephonySettings _$TelephonySettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TelephonySettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'connected',
            'account_sid',
            'from_number',
            'allow_personal_numbers',
            'daily_cap',
          ],
        );
        final val = TelephonySettings(
          connected: $checkedConvert('connected', (v) => v as bool),
          accountSid: $checkedConvert('account_sid', (v) => v as String?),
          fromNumber: $checkedConvert('from_number', (v) => v as String?),
          allowPersonalNumbers: $checkedConvert(
            'allow_personal_numbers',
            (v) => v as bool,
          ),
          dailyCap: $checkedConvert('daily_cap', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'accountSid': 'account_sid',
        'fromNumber': 'from_number',
        'allowPersonalNumbers': 'allow_personal_numbers',
        'dailyCap': 'daily_cap',
      },
    );

Map<String, dynamic> _$TelephonySettingsToJson(TelephonySettings instance) =>
    <String, dynamic>{
      'connected': instance.connected,
      'account_sid': instance.accountSid,
      'from_number': instance.fromNumber,
      'allow_personal_numbers': instance.allowPersonalNumbers,
      'daily_cap': instance.dailyCap,
    };
