// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_gate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignupGateCWProxy {
  SignupGate mode(SignupGateModeEnum mode);

  SignupGate opensAt(DateTime? opensAt);

  SignupGate invitesPerPerson(int invitesPerPerson);

  SignupGate dailyAdmit(int dailyAdmit);

  SignupGate dailyEmailsMax(int dailyEmailsMax);

  SignupGate batchHourUtc(int? batchHourUtc);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignupGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignupGate(...).copyWith(id: 12, name: "My name")
  /// ```
  SignupGate call({
    SignupGateModeEnum mode,
    DateTime? opensAt,
    int invitesPerPerson,
    int dailyAdmit,
    int dailyEmailsMax,
    int? batchHourUtc,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSignupGate.copyWith(...)` or call `instanceOfSignupGate.copyWith.fieldName(value)` for a single field.
class _$SignupGateCWProxyImpl implements _$SignupGateCWProxy {
  const _$SignupGateCWProxyImpl(this._value);

  final SignupGate _value;

  @override
  SignupGate mode(SignupGateModeEnum mode) => call(mode: mode);

  @override
  SignupGate opensAt(DateTime? opensAt) => call(opensAt: opensAt);

  @override
  SignupGate invitesPerPerson(int invitesPerPerson) =>
      call(invitesPerPerson: invitesPerPerson);

  @override
  SignupGate dailyAdmit(int dailyAdmit) => call(dailyAdmit: dailyAdmit);

  @override
  SignupGate dailyEmailsMax(int dailyEmailsMax) =>
      call(dailyEmailsMax: dailyEmailsMax);

  @override
  SignupGate batchHourUtc(int? batchHourUtc) =>
      call(batchHourUtc: batchHourUtc);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SignupGate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SignupGate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SignupGate call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? opensAt = const $CopyWithPlaceholder(),
    Object? invitesPerPerson = const $CopyWithPlaceholder(),
    Object? dailyAdmit = const $CopyWithPlaceholder(),
    Object? dailyEmailsMax = const $CopyWithPlaceholder(),
    Object? batchHourUtc = const $CopyWithPlaceholder(),
  }) {
    return SignupGate(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as SignupGateModeEnum,
      opensAt: opensAt == const $CopyWithPlaceholder()
          ? _value.opensAt
          // ignore: cast_nullable_to_non_nullable
          : opensAt as DateTime?,
      invitesPerPerson:
          invitesPerPerson == const $CopyWithPlaceholder() ||
              invitesPerPerson == null
          ? _value.invitesPerPerson
          // ignore: cast_nullable_to_non_nullable
          : invitesPerPerson as int,
      dailyAdmit:
          dailyAdmit == const $CopyWithPlaceholder() || dailyAdmit == null
          ? _value.dailyAdmit
          // ignore: cast_nullable_to_non_nullable
          : dailyAdmit as int,
      dailyEmailsMax:
          dailyEmailsMax == const $CopyWithPlaceholder() ||
              dailyEmailsMax == null
          ? _value.dailyEmailsMax
          // ignore: cast_nullable_to_non_nullable
          : dailyEmailsMax as int,
      batchHourUtc: batchHourUtc == const $CopyWithPlaceholder()
          ? _value.batchHourUtc
          // ignore: cast_nullable_to_non_nullable
          : batchHourUtc as int?,
    );
  }
}

extension $SignupGateCopyWith on SignupGate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSignupGate.copyWith(...)` or `instanceOfSignupGate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignupGateCWProxy get copyWith => _$SignupGateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupGate _$SignupGateFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SignupGate',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'mode',
        'opens_at',
        'invites_per_person',
        'daily_admit',
        'daily_emails_max',
      ],
    );
    final val = SignupGate(
      mode: $checkedConvert(
        'mode',
        (v) => $enumDecode(_$SignupGateModeEnumEnumMap, v),
      ),
      opensAt: $checkedConvert(
        'opens_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      invitesPerPerson: $checkedConvert(
        'invites_per_person',
        (v) => (v as num).toInt(),
      ),
      dailyAdmit: $checkedConvert('daily_admit', (v) => (v as num).toInt()),
      dailyEmailsMax: $checkedConvert(
        'daily_emails_max',
        (v) => (v as num).toInt(),
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

Map<String, dynamic> _$SignupGateToJson(SignupGate instance) =>
    <String, dynamic>{
      'mode': _$SignupGateModeEnumEnumMap[instance.mode]!,
      'opens_at': instance.opensAt?.toIso8601String(),
      'invites_per_person': instance.invitesPerPerson,
      'daily_admit': instance.dailyAdmit,
      'daily_emails_max': instance.dailyEmailsMax,
      'batch_hour_utc': ?instance.batchHourUtc,
    };

const _$SignupGateModeEnumEnumMap = {
  SignupGateModeEnum.open: 'open',
  SignupGateModeEnum.inviteOnly: 'invite_only',
};
