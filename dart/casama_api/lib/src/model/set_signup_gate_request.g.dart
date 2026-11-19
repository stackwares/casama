// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_signup_gate_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetSignupGateRequestCWProxy {
  SetSignupGateRequest mode(SetSignupGateRequestModeEnum? mode);

  SetSignupGateRequest opensAt(DateTime? opensAt);

  SetSignupGateRequest invitesPerPerson(int? invitesPerPerson);

  SetSignupGateRequest dailyAdmit(int? dailyAdmit);

  SetSignupGateRequest dailyEmailsMax(int? dailyEmailsMax);

  SetSignupGateRequest batchHourUtc(int? batchHourUtc);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetSignupGateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetSignupGateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetSignupGateRequest call({
    SetSignupGateRequestModeEnum? mode,
    DateTime? opensAt,
    int? invitesPerPerson,
    int? dailyAdmit,
    int? dailyEmailsMax,
    int? batchHourUtc,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetSignupGateRequest.copyWith(...)` or call `instanceOfSetSignupGateRequest.copyWith.fieldName(value)` for a single field.
class _$SetSignupGateRequestCWProxyImpl
    implements _$SetSignupGateRequestCWProxy {
  const _$SetSignupGateRequestCWProxyImpl(this._value);

  final SetSignupGateRequest _value;

  @override
  SetSignupGateRequest mode(SetSignupGateRequestModeEnum? mode) =>
      call(mode: mode);

  @override
  SetSignupGateRequest opensAt(DateTime? opensAt) => call(opensAt: opensAt);

  @override
  SetSignupGateRequest invitesPerPerson(int? invitesPerPerson) =>
      call(invitesPerPerson: invitesPerPerson);

  @override
  SetSignupGateRequest dailyAdmit(int? dailyAdmit) =>
      call(dailyAdmit: dailyAdmit);

  @override
  SetSignupGateRequest dailyEmailsMax(int? dailyEmailsMax) =>
      call(dailyEmailsMax: dailyEmailsMax);

  @override
  SetSignupGateRequest batchHourUtc(int? batchHourUtc) =>
      call(batchHourUtc: batchHourUtc);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetSignupGateRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetSignupGateRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetSignupGateRequest call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? opensAt = const $CopyWithPlaceholder(),
    Object? invitesPerPerson = const $CopyWithPlaceholder(),
    Object? dailyAdmit = const $CopyWithPlaceholder(),
    Object? dailyEmailsMax = const $CopyWithPlaceholder(),
    Object? batchHourUtc = const $CopyWithPlaceholder(),
  }) {
    return SetSignupGateRequest(
      mode: mode == const $CopyWithPlaceholder()
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as SetSignupGateRequestModeEnum?,
      opensAt: opensAt == const $CopyWithPlaceholder()
          ? _value.opensAt
          // ignore: cast_nullable_to_non_nullable
          : opensAt as DateTime?,
      invitesPerPerson: invitesPerPerson == const $CopyWithPlaceholder()
          ? _value.invitesPerPerson
          // ignore: cast_nullable_to_non_nullable
          : invitesPerPerson as int?,
      dailyAdmit: dailyAdmit == const $CopyWithPlaceholder()
          ? _value.dailyAdmit
          // ignore: cast_nullable_to_non_nullable
          : dailyAdmit as int?,
      dailyEmailsMax: dailyEmailsMax == const $CopyWithPlaceholder()
          ? _value.dailyEmailsMax
          // ignore: cast_nullable_to_non_nullable
          : dailyEmailsMax as int?,
      batchHourUtc: batchHourUtc == const $CopyWithPlaceholder()
          ? _value.batchHourUtc
          // ignore: cast_nullable_to_non_nullable
          : batchHourUtc as int?,
    );
  }
}

extension $SetSignupGateRequestCopyWith on SetSignupGateRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetSignupGateRequest.copyWith(...)` or `instanceOfSetSignupGateRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetSignupGateRequestCWProxy get copyWith =>
      _$SetSignupGateRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetSignupGateRequest _$SetSignupGateRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SetSignupGateRequest',
  json,
  ($checkedConvert) {
    final val = SetSignupGateRequest(
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecodeNullable(_$SetSignupGateRequestModeEnumEnumMap, v),
      ),
      opensAt: $checkedConvert(
        'opens_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      invitesPerPerson: $checkedConvert(
        'invites_per_person',
        (v) => (v as num?)?.toInt(),
      ),
      dailyAdmit: $checkedConvert('daily_admit', (v) => (v as num?)?.toInt()),
      dailyEmailsMax: $checkedConvert(
        'daily_emails_max',
        (v) => (v as num?)?.toInt(),
      ),
      batchHourUtc: $checkedConvert(
        'batch_hour_utc',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'opensAt': 'opens_at',
    'invitesPerPerson': 'invites_per_person',
    'dailyAdmit': 'daily_admit',
    'dailyEmailsMax': 'daily_emails_max',
    'batchHourUtc': 'batch_hour_utc',
  },
);

Map<String, dynamic> _$SetSignupGateRequestToJson(
  SetSignupGateRequest instance,
) => <String, dynamic>{
  'mode': ?_$SetSignupGateRequestModeEnumEnumMap[instance.mode],
  'opens_at': ?instance.opensAt?.toIso8601String(),
  'invites_per_person': ?instance.invitesPerPerson,
  'daily_admit': ?instance.dailyAdmit,
  'daily_emails_max': ?instance.dailyEmailsMax,
  'batch_hour_utc': ?instance.batchHourUtc,
};

const _$SetSignupGateRequestModeEnumEnumMap = {
  SetSignupGateRequestModeEnum.open: 'open',
  SetSignupGateRequestModeEnum.inviteOnly: 'invite_only',
};
