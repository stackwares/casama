// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_telephony_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetTelephonyRequestCWProxy {
  SetTelephonyRequest accountSid(String accountSid);

  SetTelephonyRequest authToken(String? authToken);

  SetTelephonyRequest fromNumber(String fromNumber);

  SetTelephonyRequest allowPersonalNumbers(bool? allowPersonalNumbers);

  SetTelephonyRequest dailyCap(int? dailyCap);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetTelephonyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetTelephonyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetTelephonyRequest call({
    String accountSid,
    String? authToken,
    String fromNumber,
    bool? allowPersonalNumbers,
    int? dailyCap,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetTelephonyRequest.copyWith(...)` or call `instanceOfSetTelephonyRequest.copyWith.fieldName(value)` for a single field.
class _$SetTelephonyRequestCWProxyImpl implements _$SetTelephonyRequestCWProxy {
  const _$SetTelephonyRequestCWProxyImpl(this._value);

  final SetTelephonyRequest _value;

  @override
  SetTelephonyRequest accountSid(String accountSid) =>
      call(accountSid: accountSid);

  @override
  SetTelephonyRequest authToken(String? authToken) =>
      call(authToken: authToken);

  @override
  SetTelephonyRequest fromNumber(String fromNumber) =>
      call(fromNumber: fromNumber);

  @override
  SetTelephonyRequest allowPersonalNumbers(bool? allowPersonalNumbers) =>
      call(allowPersonalNumbers: allowPersonalNumbers);

  @override
  SetTelephonyRequest dailyCap(int? dailyCap) => call(dailyCap: dailyCap);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetTelephonyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetTelephonyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetTelephonyRequest call({
    Object? accountSid = const $CopyWithPlaceholder(),
    Object? authToken = const $CopyWithPlaceholder(),
    Object? fromNumber = const $CopyWithPlaceholder(),
    Object? allowPersonalNumbers = const $CopyWithPlaceholder(),
    Object? dailyCap = const $CopyWithPlaceholder(),
  }) {
    return SetTelephonyRequest(
      accountSid:
          accountSid == const $CopyWithPlaceholder() || accountSid == null
          ? _value.accountSid
          // ignore: cast_nullable_to_non_nullable
          : accountSid as String,
      authToken: authToken == const $CopyWithPlaceholder()
          ? _value.authToken
          // ignore: cast_nullable_to_non_nullable
          : authToken as String?,
      fromNumber:
          fromNumber == const $CopyWithPlaceholder() || fromNumber == null
          ? _value.fromNumber
          // ignore: cast_nullable_to_non_nullable
          : fromNumber as String,
      allowPersonalNumbers: allowPersonalNumbers == const $CopyWithPlaceholder()
          ? _value.allowPersonalNumbers
          // ignore: cast_nullable_to_non_nullable
          : allowPersonalNumbers as bool?,
      dailyCap: dailyCap == const $CopyWithPlaceholder()
          ? _value.dailyCap
          // ignore: cast_nullable_to_non_nullable
          : dailyCap as int?,
    );
  }
}

extension $SetTelephonyRequestCopyWith on SetTelephonyRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetTelephonyRequest.copyWith(...)` or `instanceOfSetTelephonyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetTelephonyRequestCWProxy get copyWith =>
      _$SetTelephonyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetTelephonyRequest _$SetTelephonyRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SetTelephonyRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['account_sid', 'from_number']);
        final val = SetTelephonyRequest(
          accountSid: $checkedConvert('account_sid', (v) => v as String),
          authToken: $checkedConvert('auth_token', (v) => v as String?),
          fromNumber: $checkedConvert('from_number', (v) => v as String),
          allowPersonalNumbers: $checkedConvert(
            'allow_personal_numbers',
            (v) => v as bool?,
          ),
          dailyCap: $checkedConvert('daily_cap', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'accountSid': 'account_sid',
        'authToken': 'auth_token',
        'fromNumber': 'from_number',
        'allowPersonalNumbers': 'allow_personal_numbers',
        'dailyCap': 'daily_cap',
      },
    );

Map<String, dynamic> _$SetTelephonyRequestToJson(
  SetTelephonyRequest instance,
) => <String, dynamic>{
  'account_sid': instance.accountSid,
  'auth_token': ?instance.authToken,
  'from_number': instance.fromNumber,
  'allow_personal_numbers': ?instance.allowPersonalNumbers,
  'daily_cap': ?instance.dailyCap,
};
